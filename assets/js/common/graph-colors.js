/**
 * Series of colors for e.g. bar graph data series.
 */
const GRAPH_COLORS = [
  '#3e4053',
  '#F15854',
  '#5DA5DA',
  '#FAA43A',
  '#60BD68',
  '#F17CB0',
  '#B2912F',
  '#DECF3F',
  '#B276B2',
  '#4D4D4D',
];

/**
 * Get graph data series color for given series index.
 * @param {Number} i 
 */
function get_graph_color(i) {
  return GRAPH_COLORS[i % GRAPH_COLORS.length];
}

export { get_graph_color };
