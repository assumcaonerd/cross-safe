# Contributing to CrossSafe

First off, thank you for taking the time to contribute! It is people like you who make CrossSafe a powerful utility for smart city safety and human preservation.

By contributing to this repository, you agree to comply with our code architectural design and open-source governance.

---

## 🗺️ Git Flow & Branching Strategy

To maintain systemic stability, CrossSafe follows a strict decoupled branching workflow. All contributions must go through a pull request (PR) process.

* **`main` branch:** Represents the stable, production-ready environment. Direct commits are strictly prohibited.
* **`develop` branch:** The integration branch for features. All active development pulls from and merges back into `develop`.
* **Feature Branches (`feature/issue-[ID]-short-desc`):** Used for developing specific features or architectural requirements outlined in our issues panel.
* **Hotfix Branches (`hotfix/short-desc`):** Used for immediate patches directly affecting core telemetry or runtime components in production.

---

## 🚀 Step-by-Step Contribution Workflow

1. **Fork the Repository:** Create your own copy of the ecosystem to your profile.
2. **Clone Locally:** Clone your fork using an active SSH or HTTPS protocol.
3. **Checkout a Feature Branch:** Always branch off from the latest `develop` baseline:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/issue-[ID]-your-feature-name
   ```
4. **Implement & Test:** Keep your code clean, well-documented, and aligned with standard architectural paradigms (e.g., SOLID principles for services).
5. **Commit Progress:** Follow the [Conventional Commits](https://conventionalcommits.org) specification:
   * `feat(mobile):` for new core features.
   * `fix(backend):` for bug patches.
   * `docs(spatial):` for documentation adjustments.
6. **Push and Open a Pull Request:** Push your feature branch to your fork and submit a PR pointing specifically to CrossSafe's `develop` branch.

---

## 🔬 Code Review & Quality Gates

Every Pull Request must undergo a peer-review sequence before integration:
* **Static Analysis:** Code must pass linting rules set up within local workspace files (`.gitignore` targets).
* **Telemetry Safety:** Changes affecting spatial calculations, GPS tracking, or IMU analysis should include lightweight test validations to ensure calculation integrity.
* **Approval Requirement:** At least one core maintainer must sign off and approve the code delta before a squash-and-merge procedure takes place.

Thank you for helping us design safer streets and protect human lives!
