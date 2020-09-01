import { svg } from 'redom';

/**
 * Generate RE:DOM SVG element representing a graph button.
 * @param {string} svgId ID of the button
 * @param {string} pathData SVG path data
 * @param {Object.<string, string|number>} extraArgs Extra arguments for the RE:DOM `svg` function
 */
function graphButton(svgId, pathData, extraArgs) {
  return svg('svg',
    svg('symbol', { id: svgId, viewBox: '-4 -4 16 16', height: 32, width: 32 },
      svg('path', { d: pathData, ...extraArgs })
    ),
    svg('use', { xlink: { href: `#${svgId}` } })
  );
}

export { graphButton };
