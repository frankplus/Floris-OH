/*
 * InputHandler — owns the live inputMethodEngine.InputClient between
 * 'inputStart' and 'inputStop'. Stored in AppStorage so the keyboard panel
 * page (running in the same extension VM) can commit text. Pattern adapted
 * from the in-tree KikaInputMethod sample.
 *
 * Every editor call goes through one promise chain instead of the *Sync
 * variants. A sync call blocks our UI thread until the edited app answers, and
 * a busy app can take hundreds of ms (insertTextSync measured at 593 ms and
 * getForwardSync at 2.7 s on a loaded device) — the keyboard freezes, touch
 * handling backs up behind it, and hold timers then expire against presses the
 * user already ended, which costs keystrokes. The chain keeps the edits
 * strictly ordered while leaving the thread free to collect the next key.
 *
 * Reading back is the catch: insertText resolves once the request has been
 * accepted, not once the editor has applied it, so a getForward queued behind
 * an insert still returns the pre-insert text. The characters just before the
 * cursor are therefore shadowed here — seeded from the editor when a field is
 * bound or the caret moves, and updated from our own edits — and the
 * auto-capitalization / double-space rules read that shadow.
 *
 * NOTE on OHOS delete semantics (verified against the sample + SDK docs):
 *   deleteForward(n)  -> deletes n chars BEFORE the cursor  == Backspace
 *   deleteBackward(n) -> deletes n chars AFTER  the cursor  == forward Delete
 */
import inputMethodEngine from '@ohos.inputMethodEngine';
import { BusinessError } from '@ohos.base';

const TAIL_LEN: number = 8;     // characters of cursor context to shadow
const SEED_IDLE: number = 150;  // ms of no editing before trusting a re-read

export class InputHandler {
  private client: inputMethodEngine.InputClient | undefined = undefined;
  private kbController: inputMethodEngine.KeyboardController | undefined = undefined;
  private enterKeyType: number = inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED;
  private inputPattern: number = inputMethodEngine.PATTERN_NULL;
  private session: number = 0;
  private queue: Promise<void> = Promise.resolve();
  private tail: string = '';      // text just before the cursor, as far as we know
  private tailSeq: number = 0;
  private seedTimer: number = -1;

  static getInstance(): InputHandler {
    let inst: InputHandler | undefined = AppStorage.get<InputHandler>('inputHandler');
    if (inst === undefined) {
      inst = new InputHandler();
      AppStorage.setOrCreate('inputHandler', inst);
    }
    return inst;
  }

  // Runs `op` after everything already queued, so edits land in the order the
  // keys were pressed. A failed op is logged and the chain carries on.
  private enqueue(op: () => Promise<void>): void {
    this.queue = this.queue.then(op).catch((e: BusinessError) => {
      console.error(`FlorisIME editor op failed: ${e.code} ${e.message}`);
    });
  }

  // Re-read the cursor context from the editor. Only meaningful once our own
  // edits have settled, so unless the caller knows the queue is empty (a fresh
  // binding) it waits for a lull first, and the answer is dropped if anything
  // was typed while it was outstanding.
  private seedTail(immediate: boolean): void {
    if (this.seedTimer !== -1) {
      clearTimeout(this.seedTimer);
      this.seedTimer = -1;
    }
    const read: () => void = () => {
      const c: inputMethodEngine.InputClient | undefined = this.client;
      if (c === undefined) {
        return;
      }
      const seq: number = this.tailSeq;
      this.enqueue(async (): Promise<void> => {
        const t: string = await c.getForward(TAIL_LEN);
        if (seq === this.tailSeq) {
          this.tail = t;
        }
      });
    };
    if (immediate) {
      read();
    } else {
      this.seedTimer = setTimeout(() => {
        this.seedTimer = -1;
        read();
      }, SEED_IDLE);
    }
  }

  private edited(added: string, removed: number): void {
    this.tailSeq += 1;
    let t: string = this.tail;
    if (removed > 0) {
      t = t.substring(0, Math.max(0, t.length - removed));
      if (t.length === 0) {
        this.seedTail(false);   // shadow used up: there may be more text left of it
      }
    }
    t = t + added;
    this.tail = t.length > TAIL_LEN ? t.substring(t.length - TAIL_LEN) : t;
  }

  // The caret moved on its own (the user tapped into the text), so what we
  // think is in front of it no longer holds.
  onCaretMoved(): void {
    this.seedTail(false);
  }

  onInputStart(kb: inputMethodEngine.KeyboardController, client: inputMethodEngine.InputClient): void {
    this.kbController = kb;
    this.client = client;
    this.queue = Promise.resolve();
    this.tail = '';
    try {
      const attr: inputMethodEngine.EditorAttribute = client.getEditorAttributeSync();
      this.enterKeyType = attr.enterKeyType;
      this.inputPattern = attr.inputPattern;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`FlorisIME getEditorAttribute failed: ${err.code} ${err.message}`);
    }
    AppStorage.setOrCreate('enterKeyType', this.enterKeyType);
    AppStorage.setOrCreate('inputPattern', this.inputPattern);
    this.seedTail(true);   // nothing of ours is in flight on a fresh binding
    this.session += 1;
    AppStorage.setOrCreate('imeSession', this.session);
  }

  onInputStop(): void {
    this.client = undefined;
    this.kbController = undefined;
  }

  isAttached(): boolean {
    return this.client !== undefined;
  }

  getInputPattern(): number {
    return this.inputPattern;
  }

  insert(text: string): void {
    const c: inputMethodEngine.InputClient | undefined = this.client;
    if (c === undefined || text.length === 0) {
      return;
    }
    this.edited(text, 0);
    this.enqueue(async (): Promise<void> => { await c.insertText(text); });
  }

  backspace(): void {
    const c: inputMethodEngine.InputClient | undefined = this.client;
    if (c === undefined) {
      return;
    }
    this.edited('', 1);
    // forward = before cursor (backspace)
    this.enqueue(async (): Promise<void> => { await c.deleteForward(1); });
  }

  // Used for best-effort auto-capitalization and the double-space rule: the
  // text immediately before the cursor, from the shadow — no editor round-trip.
  textBeforeCursor(len: number): string {
    return this.tail.length > len ? this.tail.substring(this.tail.length - len) : this.tail;
  }

  enter(): void {
    const c: inputMethodEngine.InputClient | undefined = this.client;
    if (c === undefined) {
      return;
    }
    const action: number = this.enterKeyType;
    const newline: boolean = action === inputMethodEngine.ENTER_KEY_TYPE_UNSPECIFIED ||
      action === inputMethodEngine.ENTER_KEY_TYPE_NEWLINE;
    if (newline) {
      this.edited('\n', 0);
    }
    this.enqueue(async (): Promise<void> => {
      if (newline) {
        await c.insertText('\n');
      } else {
        await c.sendKeyFunction(action);
      }
    });
  }

  hideKeyboard(): void {
    if (this.kbController !== undefined) {
      this.kbController.hide();
    }
  }
}
