This repository contains tooling to assist in the management and maintencance of the PlaceOS GitHub organisation.

---

# Labels

Standard issue / PR labels are used across all repositories.
These are defined in `labels.json`.
Please use a PR for any changes to this.
Following discussion and merge, any changes will be applied to all repos via the [Sync Org Labels workflow](https://github.com/PlaceOS/.github/actions/workflows/sync-org-labels.yml).
This is an additive operation only - label properties will update, new labels will be added, however orphaned labels will _not_ be removed.

When renaming a label, use the `alias` property to specify te old name. For example:
```json
{
  "name": "type: bug",
  "alias": "bug"
}
```
This will update the label, preserving an associations with issues.

A [Delete Org Label workflow](https://github.com/PlaceOS/.github/actions/workflows/delete-org-label.yml) is available if these should be removed.
This must be manually triggered.

# Dev Builds (_WIP_)

A central workflow is available for triggering a build and publish of images to the GitHub Container Registry.

