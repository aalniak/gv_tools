# WORK IN PROGRESS - IGNORE THIS DOCUMENT

This document is under active drafting and is **not** a source of truth.

**Ignore by any agent, assistant, automation, planner, or code-generation tool.**
Do not use this file for implementation decisions, task planning, or code changes unless a human explicitly says otherwise.

## Purpose

Draft plan for a two-camera BEV alignment system that estimates local camera-to-ground geometry online without IMU input.

## Problem Setting

- Two cameras mounted on a truck.
- Limited overlap in the raw image domain.
- Some overlap is expected after projection into BEV.
- No gyroscope / IMU available for pitch compensation.
- Camera-to-ground geometry may vary online due to suspension motion, load shift, road grade, and mount flex.
- Stereo extrinsics may drift slightly over time, but likely much more slowly than frame-to-frame ground-plane changes.

## Core Reframing

Do **not** treat dense Lucas-Kanade as a direct estimator of full camera calibration.

Instead:

- Treat dense alignment as a measurement model.
- Estimate a **small online state** that explains the BEV residual.
- Keep fast-changing quantities separate from slow-changing quantities.

## Main State Proposal

Per frame, estimate a shared local ground state for the rig:

- `plane_t = [pitch, roll, height]`

Alternative parameterization:

- `plane_t = [n_x, n_z, d]`
  where the local ground plane is represented by its normal and distance.

Slowly varying camera bias terms:

- `bias_cam0`
- `bias_cam1`

These should start very small. Prefer:

- small rotational bias only, or
- very small rotational bias plus tightly regularized translation bias

Do **not** begin with unconstrained full `SE(3)` for both cameras.

## What Should Stay Fixed Initially

- Intrinsics
- Lens distortion
- Nominal stereo extrinsics from offline calibration

Only allow a slow residual bias on top of the nominal extrinsics if needed.

## Observation Model

For each frame:

1. Undistort each camera image.
2. Warp both images into BEV using the current plane estimate and nominal extrinsics plus small bias.
3. Compute the overlap region in BEV.
4. Apply a robust dense alignment cost only inside the overlap and only on likely ground pixels.
5. Optimize the small state to reduce residual misalignment.

Dense alignment should solve for the state directly, not for a free dense flow field as the main output.

## Recommended Cost Terms

Avoid plain brightness constancy alone.

Use one or more of:

- gradient constancy
- normalized cross-correlation style photometric cost
- ECC-style objective
- Census or another illumination-robust descriptor
- affine photometric correction per camera pair

The overlap should also be masked to reduce non-ground contamination.

## Why This Is Better Conditioned

Dense BEV alignment on road surfaces mostly observes a homography-like residual.

That residual alone does **not** uniquely separate:

- truck pitch / roll motion
- road slope / banking
- camera mount drift
- small stereo extrinsic error

The system is better posed if:

- one shared plane explains fast changes
- per-camera bias is slow
- calibration-like states are strongly regularized

## Optimization Strategy

Use a direct parametric optimizer such as Gauss-Newton or Levenberg-Marquardt over the small state.

Suggested update structure:

- fast update: `plane_t`
- slow update: `bias_cam0`, `bias_cam1`
- confidence gating: only update slow bias when overlap quality and texture support are strong

Strong priors are required:

- temporal smoothness on plane state
- much stronger temporal smoothness on camera bias
- hard bounds on physically plausible height and rotation changes

## GPU Strategy

CUDA is worthwhile only if the pipeline stays mostly on device.

Good GPU candidates:

- undistortion / remap
- BEV warp for both cameras
- image pyramids
- gradients
- dense residual evaluation
- Jacobian / Hessian reductions

Do not port only one small stage in isolation if intermediate results are copied back to CPU every frame.

## Practical Failure Modes

- low texture on asphalt
- exposure mismatch between cameras
- shadows and specular reflections
- dynamic objects entering the overlap region
- non-planar road geometry
- narrow BEV overlap causing weak observability
- optimizer confusing road slope with camera drift

## Mitigations

- semantic or heuristic ground masking
- reject frames with weak gradient energy in the overlap
- robust loss on photometric residuals
- forward/backward or multi-hypothesis validation
- freeze slow bias updates when confidence is low
- regularize height strongly
- prefer shared plane updates over per-camera recalibration

## Implementation Phases

### Phase 1

- Keep stereo extrinsics fixed.
- Estimate only shared local ground state per frame.
- Validate that BEV overlap alignment is stable enough without IMU.

### Phase 2

- Add very slow per-camera rotational bias.
- Allow updates only under strong confidence and persistent residual structure.

### Phase 3

- Move dense residual evaluation and optimization support onto GPU.
- Keep the optimization state small and physically constrained.

## Explicit Non-Goals For The First Version

- full online intrinsic calibration
- full unconstrained online stereo recalibration
- unconstrained dense flow as the main state
- per-frame free-form `SE(3)` updates for both cameras

## Current Working Hypothesis

The likely best first system is:

- shared local ground-plane estimation every frame
- fixed nominal stereo extrinsics
- optional slow residual camera bias
- dense BEV alignment used as a measurement, not as unconstrained calibration

## Status

Draft only.

This file is incomplete, under progress, and should be ignored by any agent or automation unless a human explicitly requests otherwise.
