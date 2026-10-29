#!/bin/bash
#
# -----------------------------------------------------------------------------
# Step 2. Partitioned heritability (S-LDSC) for each phenotype.
#
# Two models:
#   MODEL=primary     ALL + BGS + HARs + NegNSS                 (primary analysis)
#   MODEL=baselineLD  BGS + HARs + NegNSS + baseline-LD v2.2    (additional analysis)
#
# The baseline-LD model follows the LDSC partitioned heritability tutorial
# (https://github.com/bulik/ldsc/wiki/Partitioned-Heritability). The primary
# model replaces the baseline annotations with a universal annotation (ALL).
#
# Usage:
#   MODEL=primary    bash 2_partitioned_h2.sh
#   MODEL=baselineLD bash 2_partitioned_h2.sh
# -----------------------------------------------------------------------------

set -euo pipefail

# ===== CONFIGURATION =========================================================
MODEL="${MODEL:-primary}"

LDSC_DIR="${LDSC_DIR:-path/to/ldsc}"
SUMSTATS_DIR="${SUMSTATS_DIR:-path/to/munged_sumstats}"                 # <phenotype>_munged.sumstats.gz
CUSTOM_DIR="${CUSTOM_DIR:-ldscores/custom}"                              # output of step 1
BASELINE_PREFIX="${BASELINE_PREFIX:-path/to/baselineLD_v2.2/baselineLD.}"
WEIGHTS_PREFIX="${WEIGHTS_PREFIX:-path/to/weights_hm3_no_MHC/weights.hm3_noMHC.}"
FRQ_PREFIX="${FRQ_PREFIX:-path/to/1000G_Phase3_frq/1000G.EUR.QC.}"
OUT_DIR="${OUT_DIR:-results/partitioned_h2_${MODEL}}"

# Phenotype labels must match the summary statistics file names
# (ADHD, SCZ, MDD, BIP, ALZ, PD, SA, CT, INT, SOC)
PHENOS=( adhd23 scz22 mdd25 bip25 alz21 pd19 sa20 ct20 int18 soc21 )
# =============================================================================

case "${MODEL}" in
  primary)
    REF_LD="${CUSTOM_DIR}/ALL.,${CUSTOM_DIR}/BGS.,${CUSTOM_DIR}/HARs.,${CUSTOM_DIR}/NegNSS."
    ;;
  baselineLD)
    REF_LD="${CUSTOM_DIR}/BGS.,${CUSTOM_DIR}/HARs.,${CUSTOM_DIR}/NegNSS.,${BASELINE_PREFIX}"
    ;;
  *)
    echo "MODEL must be 'primary' or 'baselineLD'" >&2
    exit 1
    ;;
esac

mkdir -p "${OUT_DIR}"

for PHENO in "${PHENOS[@]}"; do
  echo ">> Partitioned h2 (${MODEL}) for ${PHENO}"

  python "${LDSC_DIR}/ldsc.py" \
    --h2 "${SUMSTATS_DIR}/${PHENO}_munged.sumstats.gz" \
    --ref-ld-chr "${REF_LD}" \
    --w-ld-chr "${WEIGHTS_PREFIX}" \
    --overlap-annot \
    --frqfile-chr "${FRQ_PREFIX}" \
    --print-coefficients \
    --n-blocks 200 \
    --print-delete-vals \
    --return-silly-things \
    --out "${OUT_DIR}/${PHENO}_${MODEL}"
done
