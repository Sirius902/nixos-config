# Comments

When a comment earns its place in an expression, and what it says when it does.

## Why this matters

A comment is the one part of a change nothing checks. An expression that drifts
stops evaluating, a patch that drifts stops applying, `checks.*` fail loudly —
a comment that drifts just sits there being wrong, and it gets believed, because
someone wrote it down. Its cost is paid on every later read, by someone with no
way to tell whether it is still true.

So the bar is both halves at once: it says something the code cannot, and it
stays true for as long as the code around it does.

## Rules

1. **No comment by default.** A comment is a conscious exception, the same
   posture `docs/commit-style.md` takes on commit bodies. Most hunks earn none.
   Gating a `buildInputs` list on `isLinux`, or swapping one extractor for
   another, reads for itself.

2. **Why, never what.** Restating the line below it in prose adds a second
   thing to keep in sync and no information.

3. **Anchor to the constraint, not the implementation.** The upstream defect,
   the spec rule, the platform limitation — those outlive the code working
   around them. The tool currently called, the alternatives rejected, and the
   exact bytes it produces do not. A comment naming `unzip` dies the day the
   line stops saying `unzip`.

4. **One reason, one comment.** A change spread over five hunks gets at most
   one comment, at the single place the reason bites — not on the argument
   list and the `nativeBuildInputs` entry and the `buildPhase` line that all
   follow from it.

5. **`TODO(<name>)` names the condition that retires it**, so a later reader
   can check whether it still applies instead of guessing. `FUTURE(<name>)`
   for work with no such condition.

## Where the reason goes

| The reason is                    | It lives in                                       |
| -------------------------------- | ------------------------------------------------- |
| why this change, now             | the commit body, if the subject doesn't carry it   |
| why this code has to stay so     | a comment, at the one line that would get "fixed"  |
| why a vendored patch exists      | that patch's own commit message                    |
| why a `fetchpatch` entry exists  | a one-liner above it, per `docs/patches.md` rule 8 |

A vendored `patches = [./foo.patch]` entry therefore takes no comment: the file
it names opens with a commit message saying everything a comment there would.
The `fetchpatch` lists in `lib/default.nix` and `overlays/` are the exception,
because a URL has no message to read.

## The shape to avoid

Swapping `unzip` for `7zz` in the sequence packs first went in as seven lines
of prose above the call, restating which tool mishandles the archives and how.
It named `unzip` twice in a hunk that had just stopped calling `unzip`, and it
explained a substitution nobody would make without a reason.

What that change needed was the line, and one sentence in the commit body.
