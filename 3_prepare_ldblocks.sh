#!/bin/bash
#
# -----------------------------------------------------------------------------
# Step 3. Prepare the LD block files for the leave-one-LD-block-out analysis.
#
#   1. Number the 1,703 European LD blocks (Berisa & Pickrell, 2016) so that
#      each block keeps its original identifier.
#   2. Select the blocks overlapping at least one HAR.
#   3. Assign each regression SNP to its block, using the SNP positions in
#      the LD score files from step 1.
#
# Outputs (in OUT_DIR):
#   blocks_all.bed         all blocks with identifiers (block1 ... block1703)
#   blocks_with_HARs.bed   blocks overlapping at least one HAR
#   blocks_with_HARs.txt   identifiers of these blocks (one per line)
#   snp_to_block.txt       SNP ID and block ID for regression SNPs in these blocks
#
# Requirements: bedtools
#
# Usage:
#   bash 3_prepare_ldblocks.sh
# -----------------------------------------------------------------------------

set -euo pipefail

# ===== CONFIGURATION =========================================================
BLOCKS_RAW="${BLOCKS_RAW:-path/to/EUR_ld_blocks.bed}"   # chr, start, stop (GRCh37), with a header line
HARS_BED="${HARS_BED:-annotations/HARs.bed}"
CUSTOM_DIR="${CUSTOM_DIR:-ldscores/custom}"             # LD scores from step 1
OUT_DIR="${OUT_DIR:-loo_blocks}"
# =============================================================================

mkdir -p "${OUT_DIR}"

# 1. Number all blocks (header removed; tab-separated output)
awk 'BEGIN{OFS="\t"} NR>1 {n++; print $1,$2,$3,"block"n}' "${BLOCKS_RAW}" > "${OUT_DIR}/blocks_all.bed"
echo "Total blocks: $(awk 'END{print NR}' "${OUT_DIR}/blocks_all.bed")"

# 2. Blocks overlapping at least one HAR
bedtools intersect -u -a "${OUT_DIR}/blocks_all.bed" -b "${HARS_BED}" > "${OUT_DIR}/blocks_with_HARs.bed"
cut -f4 "${OUT_DIR}/blocks_with_HARs.bed" > "${OUT_DIR}/blocks_with_HARs.txt"
echo "Blocks overlapping HARs: $(wc -l < "${OUT_DIR}/blocks_with_HARs.txt")"

# 3. Regression SNP positions (from the LD score files) assigned to blocks
for chr in $(seq 1 22); do
  zcat "${CUSTOM_DIR}/ALL.${chr}.l2.ldscore.gz" | \
    awk 'BEGIN{OFS="\t"} NR>1 {print "chr"$1, $3-1, $3, $2}'
done > "${OUT_DIR}/regression_snps.bed"

bedtools intersect -wa -wb -a "${OUT_DIR}/regression_snps.bed" -b "${OUT_DIR}/blocks_with_HARs.bed" | \
  awk 'BEGIN{OFS="\t"} {print $4, $8}' > "${OUT_DIR}/snp_to_block.txt"

echo "Blocks with assigned SNPs: $(cut -f2 "${OUT_DIR}/snp_to_block.txt" | sort -u | wc -l)"
