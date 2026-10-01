#import "template.typ": *
#import "tags.typ": *

#proposed Discussed 2026-09-30, after milestone 2. Nothing in this chapter is agreed yet; it records
the options so that the decisions (Q4, Q5, Q6, Q9--Q12) can be made later with the context at hand.

The deferred pieces of @ch-arch (file readers F9/F11, `mod_fm_compare`, calibration @sec-calib)
depend on each other in a fixed order: *data, then readers, then comparison, then optimization*.
The data set chosen first shapes the file format, the metadata, and which residuals matter, so it
comes first.

= Geotechnical data to compare against <sec-data>

#open-tag Q5. Candidates named in the discussion. The links and current availability have *not*
been checked yet.

#table(
  columns: (auto, 1fr),
  table.header([*Source*], [*Why it is a candidate*]),
  [Karlsruhe fine sand (Wichtmann and Triantafyllidis)], [Leading candidate. Open, one sand, many
    drained and undrained monotonic triaxial tests, oedometric and cyclic tests, published for model
    calibration (hypoplasticity, SANISAND, ...). Plain text or Excel.],
  [DesignSafe-CI Data Depot (NHERI), LEAP projects], [Ottawa F-65 sand: cyclic triaxial, DSS, and
    monotonic tests from several labs. Well documented, but each lab has its own format.],
  [Verdugo and Ishihara (1996), Toyoura sand], [The classic critical-state check: drained and
    undrained tests over a range of densities. Usually digitized from the paper, so lower quality, but
    almost every model paper compares with it.],
  [Zenodo, Mendeley Data], [More and more calibration papers deposit their raw lab data here. Search
    "triaxial" with the name of the sand.],
  [AGS4 (UK), DIGGS (US, XML)], [Exchange formats for site-investigation data. Not worth supporting
    now; useful as references when designing our own metadata (@sec-files).],
)

= From lab data to `sig(6, n)` and `eps(6, n)` <sec-lab>

Lab files are not in `fumat`'s form (F2, F3, F5). A triaxial test gives $sigma_a$, $sigma_r$ (or $q$,
$p'$), $epsilon_a$, $epsilon_v$, often pore pressure $u$; compression positive; strains often in %
and stresses in kPa. `mod_fm_lab` would

- convert units and flip signs to tension positive (F3);
- fill the Voigt arrays under axisymmetry, axis 1 vertical: $sigma_(22) = sigma_(33) = sigma_r$,
  $epsilon_(22) = epsilon_(33) = (epsilon_v - epsilon_a)\/2$, shear terms zero;
- keep the extras: initial void ratio $e_0$, consolidation stress, drainage condition, $u$.

`element-driver` needs those extras to *replay* the test (initial state and loading path), which is
where `record_t` (F11) comes back: it is to be shaped by the lab files, as F11 says, not by
`history_t`.

= File formats and readers <sec-files>

#open-tag Q4, Q9. Suggested layout: *a CSV with the numbers plus a small sidecar file with the
metadata* (test type, units, sign convention, which column holds which quantity, initial state).

#table(
  columns: (auto, auto, 1fr),
  table.header([*Need*], [*Library*], [*Notes*]),
  [numeric CSV or whitespace], [`stdlib_io` `loadtxt`, `savetxt`], [Already a dependency. In
    `../../stdlib` (`9e4c2302`, 2025-10-17) `loadtxt` takes `skiprows`, `max_rows`, and a
    one-character `delimiter` (checked). Numbers only: no column names.],
  [CSV with headers or mixed types], [`jacobwilliams/csv-fortran`], [Columns mapped by header name.],
  [JSON], [`jacobwilliams/json-fortran`], [Mature, builds with fpm.],
  [TOML], [`toml-f`], [What fpm itself uses; good for calibration run files.],
  [`.npy`], [`stdlib_io_npy`], [Already available; easy exchange with Python.],
  [HDF5, netCDF], [--], [Too heavy for element tests; not now.],
)

= Libraries for analysis <sec-libs>

- *stdlib* (already a dependency): `stdlib_stats` (mean, variance, correlation, moments),
  `stdlib_linalg` (least squares, SVD; for sensitivity and covariance at the optimum), sorting,
  strings.
- *Interpolation* for `mod_fm_compare`: `jacobwilliams/finterp` (linear) or
  `jacobwilliams/bspline-fortran`.
- *Optimizers*:
  - `fortran-lang/minpack`: Levenberg--Marquardt, already planned (@sec-calib);
  - *PRIMA* (Zaikun Zhang): modern Fortran BOBYQA, NEWUOA, COBYLA; derivative free, with bounds.
    Strongly worth considering (see @sec-opt);
  - global search: `jacobwilliams/pikaia` (genetic algorithm) or a small differential evolution
    written here.

= What kind of optimization <sec-opt>

#open-tag Q6, Q12. Calibration is *bounded, weighted, nonlinear least-squares parameter
identification over several tests*. Features of constitutive models that steer the method:

- *Noisy, non-smooth objective.* Yield-surface switches and substepping tolerances make
  finite-difference gradients unreliable. This favours a derivative-free local method (BOBYQA) over
  plain LM, or LM with carefully chosen steps.
- *Several minima, correlated parameters* (e.g. $lambda$ and $N$ trade off). Usual recipe: global
  search (differential evolution or CMA-ES), then local polish, then the Jacobian at the optimum to
  report sensitivity and identifiability.
- *Residual design, the hard part, in `mod_fm_compare`.*
  - Abscissa: $epsilon_a$ for monotonic tests; arc length or step index for cyclic or non-monotonic
    paths.
  - Normalization per quantity: $q$ in kPa and $epsilon_v$ dimensionless must be made comparable.
  - Weights per test.
- *Parameter scaling.* Optimize in normalized or log space; parameters span orders of magnitude.
- *Later:* multi-objective (Pareto front between, say, triaxial and oedometer fits), Bayesian or
  MCMC for uncertainty. Element tests are cheap, so these are feasible.

Element tests run fast and `element-driver` has no global state (D11), so a population of parameter
sets can run in parallel (OpenMP), which is an advantage of doing this in Fortran.

= Proposed order <sec-order>

+ Choose one reference data set (Karlsruhe fine sand suggested) and one model to calibrate (Q5,
  Q10).
+ `mod_fm_lab`, `mod_fm_csv`: CSV plus sidecar into Voigt arrays and initial state; revisit
  `record_t` (F11, Q4, Q9).
+ `mod_fm_compare`: interpolation, residuals, normalization; check by plotting model against data
  with the existing figures (milestone 3).
+ `simulator_t`, then LM (minpack) and BOBYQA (PRIMA) on one test, then several tests, then a
  global search (Q6, Q12).
