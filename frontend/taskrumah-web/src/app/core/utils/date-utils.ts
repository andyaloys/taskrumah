/**
 * Utility functions for local date formatting (WIB / Local timezone).
 * Avoids the notorious toISOString() bug where times before 07:00 AM WIB (UTC+7)
 * produce yesterday's date because toISOString converts to UTC (Z).
 */

export function formatLocalDate(d: Date | string = new Date()): string {
  if (!d) return '';
  // If already in YYYY-MM-DD format, return as is
  if (typeof d === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(d)) {
    return d;
  }
  const date = typeof d === 'string' ? new Date(d) : d;
  if (isNaN(date.getTime())) return '';

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function getTodayDateString(): string {
  return formatLocalDate(new Date());
}

export function getYesterdayDateString(): string {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return formatLocalDate(d);
}

export function getTomorrowDateString(): string {
  const d = new Date();
  d.setDate(d.getDate() + 1);
  return formatLocalDate(d);
}
