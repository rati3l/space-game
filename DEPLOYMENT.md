# Deploy to GitHub Pages

This repository includes a GitHub Actions workflow at `.github/workflows/deploy-pages.yml` that exports the Godot project for web and deploys it to GitHub Pages.

## One-time setup

1. In Godot, open `Project -> Export`.
2. Add a preset named `Web`.
3. Set its export path to `./index.html` (project root).
4. Export once so Godot creates `export_presets.cfg`.
5. Commit `export_presets.cfg`.

Without `export_presets.cfg`, the workflow will fail by design.

## GitHub configuration

1. Push this repository to GitHub.
2. Open `Settings -> Pages`.
3. Under "Source", select `GitHub Actions`.

After this, each push to `main` will:

- export the game with `godot --headless --export-release "Web"` using your preset's export path,
- collect web output files into `build/web`,
- deploy to GitHub Pages.

You can also run the workflow manually from the Actions tab (`workflow_dispatch`).
