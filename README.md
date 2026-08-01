# Kobi Build System

<p align="center"> <img src="https://img.shields.io/badge/System_Version-v2.4.0-blue?style=for-the-badge&logo=github" alt="System Version" /> <img src="https://img.shields.io/badge/Release_Date-July_26%2C_2026-brightgreen?style=for-the-badge&logo=calendar" alt="Release Date" /> <img src="https://img.shields.io/badge/Linux_Status-Stable-success?style=for-the-badge&logo=linux" alt="Linux Status" /> <img src="https://img.shields.io/badge/Windows_Status-In_Testing-orange?style=for-the-badge&logo=windows" alt="Windows Status" /> <img src="https://img.shields.io/badge/License-GPL--3.0--or--later-red?style=for-the-badge&logo=gnu" alt="License" /> </p>

---

## Obsidian Setup & Usage Guide

To ensure this documentation renders correctly both in Obsidian and on GitHub, please apply the following configurations in your Obsidian vault:

### 1. Mandatory Link Settings
Open **Settings** (`Ctrl + ,`) in Obsidian:
* **Files and links** $\rightarrow$ **New link format**: Select **`Path from current file`**.
* **Files and links** $\rightarrow$ **Use [[Wikilinks]]**: Toggle **OFF**.

> **Note:** GitHub does not natively parse Obsidian's default `[[Wikilinks]]`. Using standard Markdown links `[Text](path/file.md)` prevents **404 Page Not Found** errors when navigating via GitHub.

### 2. Manual Link Syntax
Use standard Markdown syntax:
* **File-to-File Link:** `[Chapter Title](docs/CHAPTER%201%20-%20INTRODUCTION.md)`
* **Link to Heading/Sub-section:** `[Jump Here](docs/CHAPTER%201.md#heading-name)`
  * *GitHub Anchor Rule:* Anchor tags after `#` must be **all lowercase**, spaces replaced with hyphens (`-`), and special characters (like backticks `` ` `` or periods) removed.

### 3. Automated GitHub Sync
Use the **Obsidian Git** plugin to push notes directly from Obsidian:
1. Install the **Obsidian Git** plugin via Community Plugins.
2. Open the Command Palette (`Ctrl + P`).
3. Run: `Obsidian Git: Commit and push all changes`.