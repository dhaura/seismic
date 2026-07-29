# Faster index construction

Optimizations to the index build. None of them changes the built index: the
produced posting lists, blocks, and summaries are identical to the previous
implementation.

- **Parallel global-threshold pruning.** The global threshold is found by
  sorting all posting scores in parallel instead of scanning them through a
  serial heap; postings are then distributed to components in parallel, with
  deterministic (thread-count-independent) handling of scores tied at the
  threshold. The old serial implementation is kept as a test oracle.
  → `global_threshold_pruning` in `src/inverted_index.rs`

- **Longest-first (LPT) posting-list dispatch.** Posting lists are built
  longest-first so a long list picked up late cannot leave the other workers
  idle; results are restored to component order afterwards.
  → the parallel loop in `InvertedIndexBase::build`, `src/inverted_index.rs`

- **Dense scratch for summaries.** The per-block `HashMap` used to accumulate
  component maxima is replaced by a dense epoch-stamped scratch table reused
  across all blocks of a posting list, and top-k selection uses
  `select_nth_unstable_by` instead of heap-based `k_largest_by`.
  → `SummaryScratch`, `accumulate_block_max`, `fixed_size_summary`,
  `energy_preserving_summary` in `src/posting_list.rs`

- **CSR inverted index for the clustering.** The temporary centroid index used
  by the random k-means is now a flat offsets + postings layout (one contiguous
  array instead of one allocation per component), built with a counting sort,
  with scores converted to `f32` once at build time.
  → `FastInvertedIndex` in `src/utils.rs`

- **Survivors-only reassignment pass.** After dissolving too-small clusters,
  documents are reassigned against an index holding only the surviving
  centroids instead of the full one, shrinking the score accumulator, the
  posting traversal, and the argmax by the same factor. Assignments are
  bit-for-bit identical to the full-index version.
  → second pass of `do_random_kmeans_on_docids_ii_approx_dot_product` in
  `src/utils.rs`

- **Exact-dot-product k-means on the same index.** The exact variant of the
  clustering builds its pruned centroid index with `FastInvertedIndex` as well
  (score-based per-component pruning via `FastInvertedIndex::pruned`) instead
  of per-component vectors.
  → `do_random_kmeans_on_docids_ii_dot_product` in `src/utils.rs`
