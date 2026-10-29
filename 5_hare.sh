#!/bin/bash
#
# -----------------------------------------------------------------------------
# Step 5. Gene-level overlap enrichment with HARE
#         (https://github.com/ossmith/HARE).
#
# For each phenotype, annotation (elements of interest, EOI) and variant
# inclusion threshold, genome-wide significant variants are mapped to the
# closest protein-coding feature (VEP, 5,000 bp) and their overlap with the
# annotation is compared with 1,000 length-matched simulated sets.
#
#   P < 1e-6  primary analysis (HARE default)
#   P < 1e-8  sensitivity analysis
#
# Usage:
#   bash 5_hare.sh
# -----------------------------------------------------------------------------

set -euo pipefail

# ===== CONFIGURATION =========================================================
VEP_CACHE="${VEP_CACHE:-path/to/vep_genome_cache}"
REF_FAI="${REF_FAI:-path/to/human_g1k_v37.fasta.fai}"        # GRCh37 reference index
GWAS_DIR="${GWAS_DIR:-path/to/hare_formatted_sumstats}"     # GRCh37 summary statistics with P, MAF, A1, A2
BED_DIR="${BED_DIR:-annotations}"                            # BED files without header
OUT_BASE="${OUT_BASE:-results/hare}"

# Phenotype label : summary statistics file
GWAS_LIST=(
  "adhd23:adhd23_hare.txt"
  "scz22:scz22_hare.txt"
  "mdd25:mdd25_hare.txt"
  "bip25:bip25_hare.txt"
  "alz21:alz21_hare.txt"
  "pd19:pd19_hare.txt"
  "sa20:sa20_hare.txt"
  "ct20:ct20_hare.txt"
  "int18:int18_hare.txt"
  "soc21:soc21_hare.txt"
)

ANNOTS=( BGS HARs NegNSS )

# HARE parameters
PVAL_COL="P"
MAF_COL="MAF"
REF_COL="A1"
ALT_COL="A2"
DIST=5000
N_SIM=1000
BIOTYPES="protein_all"
PVAL_THRESHOLDS=( "1e-6" "1e-8" )
# =============================================================================

for G in "${GWAS_LIST[@]}"; do
  GWAS_TAG="${G%%:*}"
  GWAS="${GWAS_DIR}/${G#*:}"

  for EOI_TAG in "${ANNOTS[@]}"; do
    EOI="${BED_DIR}/${EOI_TAG}.bed"

    for PVAL_THRES in "${PVAL_THRESHOLDS[@]}"; do
      OUT_DIR="${OUT_BASE}/${GWAS_TAG}/${EOI_TAG}/p_${PVAL_THRES}"
      mkdir -p "${OUT_DIR}"
      OUT_STEM="${OUT_DIR}/${EOI_TAG}_${GWAS_TAG}_p${PVAL_THRES}_dist${DIST}_n${N_SIM}"

      echo ">> HARE: ${GWAS_TAG} | ${EOI_TAG} | P < ${PVAL_THRES}"

      hare intersect \
        --gwas "${GWAS}" \
        --gwas_p "${PVAL_COL}" \
        --pval "${PVAL_THRES}" \
        --gwas_maf "${MAF_COL}" \
        --gwas_ref "${REF_COL}" \
        --gwas_alt "${ALT_COL}" \
        --biotypes "${BIOTYPES}" \
        --eoi "${EOI}" \
        --dist "${DIST}" \
        --ref "${REF_FAI}" \
        --cache_dir "${VEP_CACHE}" \
        --out "${OUT_STEM}" \
        --draws "${N_SIM}"

      hare sigtest --input "${OUT_STEM}.intersections" --out "${OUT_STEM}"
    done
  done
done

echo "All runs completed. Output: ${OUT_BASE}"
