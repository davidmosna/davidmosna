# CLAUDE.md — davidmosna.cz

This file is the single source of truth for how Claude Code operates in this project.
Read it fully before taking any action.

---

## Project Structure

```
src/
  index.md              — homepage
  kontakt.md            — contact page
  recepty.md            — master recipe index (all recipes listed here)
  recepty/
    <recipe-slug>/
      index.md          — individual recipe page
      cover.webp        — cover image (always this exact filename and format)
reference-images/
  acceptable/           — visual examples of images that meet quality standards
  unacceptable/         — visual examples of images that fail quality standards
```

---

## Adding a New Recipe

### How to invoke

```bash
# Standard — Claude handles everything automatically
> Add this recipe: https://...

# User provides a specific cover image URL
> Add this recipe: https://... --image https://...

# Skip image entirely
> Add this recipe: https://... --no-image

# Skip duplicate check (used after a duplicate warning was reviewed and approved)
> Add this recipe: https://... --force
```

---

## Step 1 — Fetch the Recipe

Use WebFetch to retrieve the full page content at the provided URL.

Extract the following fields:
- **Title** — short, clear, in Czech. Remove filler words. Max ~6 words.
- **Servings** — number of portions
- **Total time** — total preparation + cooking time combined as a single number in minutes. If the source shows separate times (prep, wait, cook), sum them. Details about individual phases belong in the preparation steps, not in the header.
- **Ingredients** — grouped if the source uses groups, each with exact quantity and unit. Czech names, Czech units (lžíce, lžička, hrst, špetka, ml, g, kg, ks).
- **Instructions** — numbered steps in Czech, clear and actionable
- **Nutrition** — optional, only include if explicitly stated on the source page. Do not estimate or infer.
- **Cover image URL** — the main recipe image from the source page
- **Source URL** — the original URL provided by the user

If the page cannot be fetched or the content is insufficient to extract a complete recipe, stop and report the specific reason to the user. Do not attempt to guess or fill in missing data.

---

## Step 2 — Duplicate Check

Before creating any files, read `src/recepty.md` and compare the new recipe against every existing entry.

This is a **semantic comparison**, not string matching. Consider:
- Same dish with minor variation in name (including Czech vs English names)
- Same core ingredients in the same proportion even if the title differs
- Regional or naming variants of the same base recipe

### Decision thresholds

| Similarity | Action |
|---|---|
| Near-identical (same dish, negligibly different) | Open a GitHub Issue (see format below), stop all file operations |
| Suspicious but unclear (same base dish, meaningfully different variation) | Continue to PR, add label `possible-duplicate`, include warning in PR body |
| Not similar | Continue normally |

### GitHub Issue format for duplicates

```
Title: ⚠️ Možný duplicitní recept: <new recipe title>

Body:
**Nový recept:** <title>
**Zdroj:** <source URL>

**Možná shoda:** [<existing title>](<existing path>)
**Důvod:** <one sentence explaining the similarity in Czech>

---
Pokud chceš pokračovat, přidej komentář „proceed" a spusť příkaz znovu s příznakem `--force`.
Pokud jde o duplicitu, issue zavři.
```

Label the issue: `duplicate-check`

After opening the issue, stop. Do not create any files or branches.

### --force flag

If `--force` is present, skip duplicate detection entirely. Close any open `duplicate-check` issue for this recipe URL if one exists (search by URL in the issue body), then continue to Step 3.

---

## Step 3 — Cover Image

Evaluate the cover image from the source page. Download it and assess visually against these criteria, using the examples in `reference-images/` as your calibration:

**Acceptable image:**
- Minimum 900px wide
- The food is the clear, dominant subject of the photo
- Good lighting — natural or studio, no harsh shadows, no severe underexposure
- Sufficient sharpness and detail on the food itself
- See `reference-images/acceptable/` for visual examples

**Unacceptable image:**
- Blurry or low resolution
- Food is small, in the background, or obscured
- Very dark, washed out, or heavily filtered
- Lifestyle/context shot where the food is incidental
- See `reference-images/unacceptable/` for visual examples

### Decision tree

```
--no-image flag present?
  YES → skip cover image, do not include image line in markdown

--image <url> flag present?
  YES → download that URL, use it directly, skip evaluation

Does the original source image pass quality check?
  YES → use it
  NO  →  Search for an alternative (see below)
        Found acceptable candidate? → use it
        Nothing acceptable found?  → proceed without cover image, note it in PR body
```

### Automatic image search

If the source image fails and no override URL was provided, search for a replacement using the recipe title as the query. Target food photography sources (Unsplash preferred). Evaluate each candidate against the same criteria above. Use the first one that passes. If nothing passes after a reasonable search, proceed without a cover image.

### Image processing

Whichever image is selected:
1. Download it
2. Convert to `.webp` format
3. Save as `src/recepty/<slug>/cover.webp`

---

## Step 4 — Generate Files

### Slug rules
- Lowercase Czech, no diacritics (á→a, č→c, ě→e, í→i, ž→z, š→s, ů→u, ú→u, ř→r, ý→y, etc.)
- Words separated by hyphens
- No trailing hyphens, no double hyphens
- Example: "Kuře po toskánsku" → `kure-po-toskansku`

### File 1 — `src/recepty/<slug>/index.md`

Follow this format exactly. Do not add, remove, or reorder sections unless the optional ones are absent from the source.

```markdown
# <Title>
**Na <N> porce** | ⏱️ <T> minut

![](cover.webp)

**<Ingredient group label>:**

- <quantity> <ingredient>
- <quantity> <ingredient>

**<Next group label>:**

- <quantity> <ingredient>

## Postup

1. <Step one>

2. <Step two>

## Výživové hodnoty (optional — include only if data exists)

| | Na 100 g | Na porci |
|---|---|---|
| Energie | | |
| Bílkoviny | | |
| Sacharidy | | |
| Tuky | | |

## Zdroj
[<domain only, no https://>](<full source URL>)
```

**Rules:**
- If there is only one ingredient group, omit the group label and list ingredients directly without a bold header
- If there is no cover image, omit the `![](cover.webp)` line entirely
- If there are no nutrition values, omit the `## Výživové hodnoty` section entirely
- The `## Zdroj` section is always present
- Blank line between each ingredient group
- Blank line between each numbered step

### File 2 — append to `src/recepty.md`

Add one line under the correct section heading (`## Hlavní jídla`, `## Sladké`, `## Pomazánky`, etc.). Insert it in **alphabetical order** within that section.

```markdown
- [<Title>](/recepty/<slug>)
```

If the recipe does not clearly belong to an existing section, use `## Hlavní jídla` as the default and note this in the PR body.

---

## Step 5 — Create the Pull Request

### Branch
```
recipe/<slug>
```

### Commit message
```
recipe: add <title>
```

### PR title
```
Recipe: <Title>
```

### PR body template

```markdown
## <Title>

**Zdroj:** <source URL>
**Porce:** <N>
**Čas:** <T> minut

### Cover image
<one of:>
- ✅ Original source image used
- ✅ User-provided image used (<url>)
- ✅ Automatically sourced from <source> (<url>)
- ⚠️ No cover image — no acceptable image found

### Varování
<omit this section if no warnings>
- ⚠️ possible-duplicate: Similar to [<title>](<path>) — <one line reason>

### Změny
- `src/recepty/<slug>/index.md` — new file
- `src/recepty/<slug>/cover.webp` — new file (or "not included")
- `src/recepty.md` — added entry under <section>
```

### Labels
- Always add: `recipe`
- Add if applicable: `possible-duplicate`, `no-cover-image`

---

## Language

All generated recipe content is in **Czech**. Ingredient names, units, instruction text, section headings — everything Czech. The only exception is proper nouns that are conventionally kept in their original language (e.g. "stir-fry", "frittata").

---

## What Claude Must Never Do

- Do not estimate or hallucinate nutrition values
- Do not invent ingredients or steps not present in the source
- Do not proceed past Step 2 if a near-identical duplicate is found
- Do not use any image filename other than `cover.webp`
- Do not modify any file other than `src/recepty.md` and the new recipe directory
- Do not merge or close PRs — that is always a human action
