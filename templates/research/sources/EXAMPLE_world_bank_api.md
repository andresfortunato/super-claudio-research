---
source: world_bank_api
status: verified 2026-05-06        # verified <date> | stale | retired
triggers: "world bank wdi indicator api country iso3 gdp per capita open data"
wrapper: none                      # function in <project>_utils.py, or "none"
env: [none]                        # env-var names, or [none]
---

# World Bank Open Data API — indicator time series by country and year

> **This is a template / worked example** of the shape
> `.claude/conventions/sources.md` requires: five sections, in this order,
> with a re-fetchable anchor. Replace it with your project's real
> `<source>_<thing>.md` files, or delete it once real sources are documented,
> and drop its rows from `INDEX.md`. The indicator value below is
> illustrative — re-fetch before relying on it.

## What it gives you

Annual time series for ~1,400 development indicators across ~217 countries and
~48 aggregates, from 1960 to the most recent published year. This is the
delivery API for the World Development Indicators (WDI) and about sixty other
World Bank databases.

- **Unit of observation**: country × indicator × year. A handful of indicators
  are monthly or quarterly (`2024M03`, `2024Q1` date forms).
- **Codelists**: indicators are dotted codes (`NY.GDP.PCAP.CD`); countries are
  ISO3 (`VNM`, `KHM`), with World-Bank-internal codes for aggregates (`EAS` =
  East Asia & Pacific, `LMC` = Lower Middle Income).
- **Units are per-indicator and are in the metadata, not the data.** The same
  indicator family ships current US$, constant 2015 US$, PPP and local-currency
  variants under different codes. `/indicator/{code}` returns the unit string;
  read it before comparing two series.
- **Vintage**: the API always serves the latest revision. There is no
  as-of-date parameter (see *Coverage limits*).

**Authoritative spec**:
<https://datahelpdesk.worldbank.org/knowledgebase/topics/125589>

## Access

Base URL `https://api.worldbank.org/v2`. **No auth, no API key, no env vars**
for public indicators. Rate limits are unpublished but generous; back off on
`429`.

Minimal call, copy-pasteable:

```
GET https://api.worldbank.org/v2/country/VNM/indicator/NY.GDP.PCAP.CD?format=json&date=2000:2023&per_page=200
```

Two endpoint families do almost all the work:

| Family | Path | Purpose |
|---|---|---|
| **Indicator data** | `/country/{ISO}/indicator/{indicator}` | Time series for one or many ISO3 codes on one or many indicators. |
| **Indicator metadata** | `/indicator/{indicator}` | Name, description, source database, **unit**. |

Plus `/country`, `/source`, `/topic`, `/region`, `/incomeLevel` for browsing the
catalog. **Add `?format=json` to every request** — the default is XML.

| Param | Purpose | Default |
|---|---|---|
| `format` | `json` (almost always) or `xml` | `xml` |
| `date` | Year (`2022`), range (`2010:2023`), or month (`2024M03`) | all years |
| `per_page` | Page size; max ~32,500 | **50 (paginated!)** |
| `page` | 1-indexed page number | 1 |
| `mrv` | "Most recent value" — the last N observations | — |
| `gapfill` | `Y` to forward-fill missing years from prior obs | `N` |
| `source` | Pin to one source database (`2` = WDI) | unpinned |

Semicolon-join for multi-country or multi-indicator pulls; `all` means every
country:

```
/v2/country/VNM;THA;PHL/indicator/NY.GDP.PCAP.CD?format=json
/v2/country/all/indicator/NY.GDP.PCAP.CD;SP.POP.TOTL?format=json&source=2
```

**Decoding.** The response is a length-2 array, `[meta_dict, list_of_obs]`:

```python
import requests, pandas as pd

URL = ('https://api.worldbank.org/v2/country/VNM/indicator/'
       'NY.GDP.PCAP.CD?format=json&date=2000:2023&per_page=200')
meta, obs = requests.get(URL, timeout=60).json()
assert len(obs) == meta['total'], f"paginated: got {len(obs)} of {meta['total']}"

df = pd.DataFrame([
    {'iso3': o['countryiso3code'],
     'indicator': o['indicator']['id'],
     'year': int(o['date']),
     'value': o['value']}          # None for missing obs — not omitted
    for o in obs
]).dropna(subset=['value'])
df['value'] = pd.to_numeric(df['value'])
```

**Prefer a package unless you need a raw parameter.** `wbgapi` (Python) and
`wbstats` / `WDI` (R) wrap the same API with far less boilerplate. Drop to raw
`requests` only for parameters they don't expose — `gapfill`, `source` pinning.
If this project wraps it, the wrapper goes in `<project>_utils.py`, its
docstring back-links here, and the `wrapper:` key above names it.

## Headline anchor

| Indicator | Country | Year | Value |
|---|---|---|---|
| `NY.GDP.PCAP.CD` (GDP per capita, current US$) | `VNM` (Vietnam) | 2022 | ≈ 4,164 |

Re-run the minimal call above and check this triple. A stale `status:` date
paired with a drifted value is the signal the doc needs a refresh; a date with
no anchor beside it cannot be checked at all. See "Verifiable freshness anchors"
in `docs/audience-and-philosophy.md`, in the framework repo (`r2p init` does not
install `docs/`).

**Pick a stable historical value, not a fresh one.** A 2010s GDP-per-capita
figure barely moves; a 2024 estimate is revised routinely, so it would report
drift that says nothing about whether the API still behaves as documented.

## Gotchas

1. **Pagination defaults to 50 rows and truncates silently.** *Symptom*: a
   full-history pull returns exactly 50 observations. *Fix*: pass
   `per_page=200` or higher, and assert `len(obs) == meta['total']` — the
   `assert` in the snippet above is there for this.
2. **Missing observations arrive as `value: null`, not as absent rows.**
   *Symptom*: a "dense" series that silently contains `None`, and a mean that
   comes back as `NaN` or is computed over the wrong denominator. *Fix*: filter
   or impute deliberately; never assume the array is dense.
3. **The same indicator code exists in several source databases.** *Symptom*: a
   value disagrees with another reference by a few percent for no obvious
   reason. *Fix*: pin `source=2` (WDI) for macro indicators; you may have
   pulled an REO vintage (`source=11`, `source=15`).
4. **Aggregates are mixed into country lists.** *Symptom*: `/country/all`
   returns ~265 entries and a per-country mean is wrong because income groups
   and regions are in the sample. *Fix*: filter `region.id != 'NA'`, or pass an
   explicit ISO3 list.
5. **ISO3 mostly works, but not always.** *Symptom*: a legacy aggregate returns
   empty for its ISO3-looking code. *Fix*: `/v2/country` enumerates the real
   codes; aggregates use World Bank internal ones.
6. **A year label is not a publication date.** *Symptom*: a figure tagged `2022`
   changes between two pulls months apart. *Fix*: the API serves the latest
   revision and cannot be pinned — see *Coverage limits*. Cache the response
   under `data/raw/` and cite the fetch date if reproducibility matters.

## Coverage limits

- **No as-of / vintage parameter.** You cannot ask for "WDI as published in
  April 2023". Reproducing a number against a publication date requires a cached
  copy of the response, or the archived WDI bulk downloads.
- **Annual only, for practical purposes.** A handful of indicators carry monthly
  or quarterly dates; anything higher-frequency needs the source statistical
  agency directly.
- **Aggregation is the World Bank's, not yours.** Regional and income-group
  values are computed on their own weighting and coverage rules. If your unit is
  a custom country group, pull country-level and aggregate yourself.
- **Sub-national is out of scope.** Provinces, cities and functional urban areas
  are not here; that needs a national statistics office or a geospatial source.
- **Coverage is uneven before ~1990** and for small states throughout. Check
  `meta['total']` against the year range you asked for before treating a gap as
  a zero.
