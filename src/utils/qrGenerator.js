/**
 * Generates an SVG QR Code representation string for reservation verification.
 * Creates an authentic-looking QR matrix based on hash string.
 */
export function generateQRCodeSVG(text, size = 180) {
  // Deterministic 15x15 matrix generation based on order code
  const matrixSize = 17;
  const cellSize = size / matrixSize;
  
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash = (hash << 5) - hash + text.charCodeAt(i);
    hash |= 0;
  }

  const rects = [];
  
  // Outer position pattern boxes (top-left, top-right, bottom-left)
  const drawPositionPattern = (startX, startY) => {
    for (let r = 0; r < 5; r++) {
      for (let c = 0; c < 5; c++) {
        const isBorder = r === 0 || r === 4 || c === 0 || c === 4;
        const isCenter = r >= 1 && r <= 3 && c >= 1 && c <= 3;
        const isInnerCore = r === 2 && c === 2;

        if (isBorder || isInnerCore) {
          rects.push(
            `<rect x="${(startX + c) * cellSize}" y="${(startY + r) * cellSize}" width="${cellSize}" height="${cellSize}" fill="#0f172a" rx="1"/>`
          );
        }
      }
    }
  };

  // Draw 3 position anchors
  drawPositionPattern(0, 0);
  drawPositionPattern(matrixSize - 5, 0);
  drawPositionPattern(0, matrixSize - 5);

  // Fill in pseudo-random data pixels based on text hash
  let localHash = Math.abs(hash);
  for (let r = 0; r < matrixSize; r++) {
    for (let c = 0; c < matrixSize; c++) {
      // Skip position patterns
      const isTL = r < 5 && c < 5;
      const isTR = r < 5 && c >= matrixSize - 5;
      const isBL = r >= matrixSize - 5 && c < 5;
      
      if (!isTL && !isTR && !isBL) {
        localHash = (localHash * 1664525 + 1013904223) % 4294967296;
        if (localHash % 2 === 0) {
          rects.push(
            `<rect x="${c * cellSize}" y="${r * cellSize}" width="${cellSize}" height="${cellSize}" fill="#1e293b" rx="1"/>`
          );
        }
      }
    }
  }

  return `
    <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg" style="border-radius: 12px; background: #ffffff; padding: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08);">
      ${rects.join('')}
    </svg>
  `;
}
