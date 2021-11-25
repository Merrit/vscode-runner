A KRunner plugin / "runner" that searches recent workspaces in VSCode and lists
results to quickly re-open the workspace in VSCode by pressing `Enter`, or open
the project's directory by pressing `Shift` + `Enter`.

... get from store.kde.org ...

Video:
<video>
    <source src="assets/screenshots/demo.mp4">
</video>

MD Video:
![](assets/screenshots/demo.mp4)
... screenshots ...

## Building

```bash
dart pub get
```

```bash
dart compile exe -o package/vscode_runner bin/vscode_runner.dart
```


## Install plugin

```bash
package/install.sh
```


## Uninstall plugin

```bash
package/uninstall.sh
```
