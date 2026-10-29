#!/bin/bash
#
# -----------------------------------------------------------------------------
# Step 1. Build annotation files and compute LD scores for the custom
#         annotations (ALL, BGS, HARs, NegNSS) for chromosomes 1-22.
#
# Follows the LDSC partitioned heritability tutorial for new annotations
# (https://github.com/bulik/ldsc/wiki/Partitioned-Heritability), with the
# addition of a universal annotation (ALL) used in the primary model.
#
# Usage:
#   bash 1_make_annots_ldscores.sh                # all chromosomes
#   CHRS="21 22" bash 1_make_annots_ldscores.sh   # selected chromosomes
# -----------------------------------------------------------------------------

set -euo pipefail

# ===== CONFIGURATION =========================================================
LDSC_DIR="${LDSC_DIR:-path/to/ldsc}"                                          # contains make_annot.py and ldsc.py
BFILE_PREFIX="${BFILE_PREFIX:-path/to/1000G_EUR_Phase3_plink/1000G.EUR.QC}"   # PLINK prefix (without chromosome number)
HM3_SNPS="${HM3_SNPS:-path/to/hm3_no_MHC.list.txt}"                           # HapMap3 SNP list without MHC
BED_DIR="${BED_DIR:-annotations}"                                             # BGS.bed, HARs.bed, NegNSS.bed
OUT_DIR="${OUT_DIR:-ldscores/custom}"                                         # output annotations and LD scores
CHRS="${CHRS:-$(seq 1 22)}"
# =============================================================================

mkdir -p "${OUT_DIR}"

for chr in ${CHRS}; do
  echo ">> Chromosome ${chr}"

  # --- ALL: universal annotation (value 1 for every SNP in the .bim file) ----
  awk 'BEGIN{print "ANNOT"} {print 1}' "${BFILE_PREFIX}.${chr}.bim" | gzip > "${OUT_DIR}/ALL.${chr}.annot.gz"

  python "${LDSC_DIR}/ldsc.py" --l2 \
    --bfile "${BFILE_PREFIX}.${chr}" \
    --ld-wind-cm 1 \
    --annot "${OUT_DIR}/ALL.${chr}.annot.gz" \
    --thin-annot \
    --print-snps "${HM3_SNPS}" \
    --out "${OUT_DIR}/ALL.${chr}"

  # --- Evolutionary annotations ----------------------------------------------
  for name in BGS HARs NegNSS; do
    python "${LDSC_DIR}/make_annot.py" \
      --bed-file "${BED_DIR}/${name}.bed" \
      --bimfile "${BFILE_PREFIX}.${chr}.bim" \
      --annot-file "${OUT_DIR}/${name}.${chr}.annot.gz"

    python "${LDSC_DIR}/ldsc.py" --l2 \
      --bfile "${BFILE_PREFIX}.${chr}" \
      --ld-wind-cm 1 \
      --annot "${OUT_DIR}/${name}.${chr}.annot.gz" \
      --thin-annot \
      --print-snps "${HM3_SNPS}" \
      --out "${OUT_DIR}/${name}.${chr}"
  done
done
