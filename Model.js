function clampBrightness(value, min, max) {
  var n = Number(value)
  if (!isFinite(n)) return Number(min)
  return Math.max(Number(min), Math.min(Number(max), Math.round(n)))
}

function brightnessName(percent) {
  var p = Math.round(Number(percent))
  if (p >= 95) return "Sun blast"
  if (p >= 80) return "Solar flare"
  if (p >= 65) return "Golden hour"
  if (p >= 45) return "Even day"
  if (p >= 30) return "Soft glow"
  if (p >= 20) return "Lamp light"
  if (p >= 10) return "Night owl"
  return "Total darkness"
}

if (typeof module !== "undefined") {
  module.exports = {
    clampBrightness: clampBrightness,
    brightnessName: brightnessName
  }
}