# csm-analysis
A modern Fortran library for analyzing, plotting, and general data processing of results from constitutive models: element tests, FEM, MPM. It is also the home for parameter sensitivity studies and calibration as they are added. With the modern fortran ecosystem it's possible to do all of the analysis that would normally be done in python in fortran. 

There are a couple of benefits to doing the data processing in fortran rather than python.
1) Fortran is really fast. We can do a lot of testing and plotting quickly.
2) Alot of constitutive models are written in fortran so you don't have to deal with the two language problem.
3) Fortran is able to interop with C so interacting with C++ and C constitutive models is also straight forward.
4) You're able to do the analysis while stepping through the debugger. So you can immediately see the data you're working with.
5) Fortran is cool. (Fortran is dead. Long live Fortran)

## What it does

csm-analysis takes stress and strain histories, `sig(6, n)` and `eps(6, n)` in Voigt order
`[11, 22, 33, 12, 13, 23]` with engineering shear strain and tension positive, from any
solver, and plots and analyzes them. The library does not depend on any solver or constitutive
model. [element-driver](https://github.com/CriticalSoilModels/element-driver) is a
*dev-dependency*, used only by the examples (e.g. `example/triaxial_mcss.f90`). Invariants come from [csm-tensors](https://github.com/CriticalSoilModels/csm-tensors).

```fortran
use csm_analysis, only: quad_plot_t
type(quad_plot_t) :: fig
call fig%add(history%sig, history%eps, label="100 kPa")
fig%compression_positive = .true.      ! default: plot as stored (compression negative)
call fig%save("output/triaxial.png", status)
```

Figures:
- `quad_plot_t`: q vs eps_q, q vs p, eps_v vs eps_q, eps_v vs p (q and eps_q are the
  invariants sqrt(3 J2) and sqrt(2/3 e:e)).
- `oedometer_plot_t`: vertical stress vs axial strain, and horizontal vs vertical stress.
- `xy_plot_t`: any x-y curves on one set of axes (Lode angle, state variables, K0, ...).

Design decisions, open questions, and the change log are in `notes/csm_analysis.pdf`
(source `notes/csm_analysis.typ`).

## Building

csm-analysis is built with the [Fortran Package Manager (fpm)](https://github.com/fortran-lang/fpm)
and gfortran. Install conda ([Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/install)),
then create the environment shared with critical-soil-models:

```bash
conda env create --file=environment.yml
conda activate fpm
```

Dependencies (see `fpm.toml`): `stdlib` checked out at `../../stdlib`, `csm-tensors` at
`../csm-tensors`, and `fortplot` from GitHub.

```
fpm build                                   # debug build
fpm test                                    # run the tests
fpm run --example quad_plot_synthetic       # writes output/quad_plot_synthetic*.png
fpm run --example oedometer_plot_synthetic  # writes output/oedometer_*synthetic.png
typst compile --root . notes/csm_analysis.typ      # the developer notes
ford fpm.toml                               # API documentation (not published yet)
```

## License
<!-- 
The critical-soil-models source code and related files and documentation are distributed under a permissive free software [license](https://github.com/CriticalSoilModels/Incremental_Driver/LICENSE) (BSD-style). -->
