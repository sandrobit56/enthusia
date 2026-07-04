# Visual Edits Cheat Sheet — Enthusia

Quick reference for editing screens safely. Visual changes don't break the app. Logic changes can. Know the difference before editing.

## Safe to change (visual only)

### Spacing
- `SizedBox(height: AppSpacing.m)` → change `m` to `s`, `l`, `xl`, etc.
- `padding: EdgeInsets.symmetric(horizontal: AppSpacing.m)` → adjust value
- `EdgeInsets.all(...)`, `EdgeInsets.only(top: ...)` — safe

### Alignment & position
- `MainAxisAlignment.center` → `start`, `end`, `spaceBetween`, `spaceAround`
- `CrossAxisAlignment.start` → `center`, `end`, `stretch`
- `Alignment.center` → `centerLeft`, `topRight`, etc.

### Order
- Inside a `Column` or `Row`, you can drag children up/down in the `children: [...]` list to reorder them

### Size
- `width:` and `height:` on `Container`, `SizedBox`, `Image`
- Don't change to `double.infinity` or `0` unless you know why

### Layout helpers
- `Spacer()` — pushes things apart
- `Expanded(child: ...)` — fills available space
- `Flexible(child: ...)` — shrinks if needed

### Colors (only via tokens)
- Change `AppColors.primary` to `AppColors.accent` — safe
- Never write `Color(0xFF...)` directly in a screen file

### Text
- `Text('Hello')` → change the string
- `style: AppTextStyles.body` → swap to `h1`, `h2`, `caption`, etc.

## DO NOT change (this is logic)

### Callbacks
- `onTap: () => _goToHome(context)` — function body is logic
- `onPressed: () { ... }` — anything inside `{}` is logic
- `onChanged: (value) => setState(...)` — logic

### Navigation
- `Navigator.of(context).push(...)`, `pushReplacement(...)` — logic

### State
- `setState(() => ...)` — logic
- `final bool _isLoading = false` — state declaration, logic

### Method bodies
- Anything between `{` and `}` inside a function definition — logic

### Imports
- `import '...'` lines at top of file — don't touch unless you know

## Safe editing workflow

1. Make ONE change at a time
2. Save (Ctrl+S)
3. Hot reload (`r` in flutter terminal)
4. Look at phone — did it change correctly?
5. If yes → next change. If broken → Ctrl+Z to undo.

## When in doubt

Ask Claude before editing. Cheaper than debugging later.
