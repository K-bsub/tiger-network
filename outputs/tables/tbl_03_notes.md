# Notes for tbl_03_reserve_network.csv and tbl_03b_pinch_points.csv

Written by scripts/07_connectivity.R STEP 12.6. The script writes this file again on each run: do not edit it by hand. The field list is in docs/data-dictionary.md. The rules are in docs/methodology.md, Decisions 19 and 20.

## What a "pinch point" is in these tables

- A place where a barrier road meets a modelled least-cost path between two tiger reserves, at a site that a bridge link uses or that 2 or more links share.
- It is NOT the pinch point of circuit-theory mapping (a narrow part of a corridor with high current flow). A least-cost path has no width.
- Barrier road: an OpenStreetMap road of class motorway, trunk, primary, secondary. The road class is a description. It is not a traffic volume and it is not in the rule.
- Site: road crossings at most 5 km apart are one site. One row of tbl_03b is one site.
- Bridge link: a link of the reserve network without which its set of joined nodes divides.

## Tiers

- Tier 1: the site is on a bridge link and it is shared.
- Tier 2: the site is on a bridge link only.
- Tier 3: 2 or more links share the site; no bridge link uses it.
- The sites in one tier have no order between them.

## Limits

- The paths and the road crossings are modelled. They are not observed tiger movement, and they are not records of tigers on roads.
- The resistance surface is India-only: a path cannot go through a neighbour country.
- Position: each pinch point is given as a 10 km grid cell with its state and district, and not more precisely (docs/sensitive-data-policy.md, section 3). The districts are those of the 2011 census.
- Variant result for the pinch points (Decision 20 point 6): gHM multiplier sensitive; road value robust. In tbl_03b, n_variants_near is the number of variant surfaces (0 to 3) that have a pinch point within 5 km of the site.
- Linchpin (tbl_03): a node with a betweenness rank from 1 to 3 in its set of joined nodes. The number 3 is a judgement value: read the label with set_size.
- Node counts (tbl_03): the values are per node, and the reserves of one node share them. A site on a link counts for the two nodes of the link, so the node counts do not add up to the number of pinch points. The count gives no order of nodes.

## Counts of this run

- tbl_03: 56 reserves in 47 nodes.
- tbl_03b: 200 pinch points (tier 1: 3, tier 2: 98, tier 3: 99).
