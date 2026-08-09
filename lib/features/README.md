# Feature-First MVVM Structure

This folder is the migration target for a scalable architecture.

- `labs/` contains the first complete feature vertical.
- `alerts/`, `dashboard/`, and `backup_restore/` can follow the same pattern.

Pattern per feature:

- `domain/`: entities, repository contracts, and use cases.
- `data/`: datasource + repository implementations.
- `presentation/`: views, widgets, and viewmodels.
