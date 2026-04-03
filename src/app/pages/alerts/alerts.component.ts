import { Component, OnInit } from '@angular/core';
import { CommonModule,DatePipe  } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { ApiService } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';
import { PackCatalogService } from '../../core/pack-catalog.service';

@Component({
  selector: 'app-alerts',
  standalone: true,
  imports: [CommonModule, FormsModule, MatTableModule, MatButtonModule, DatePipe],
  templateUrl: './alerts.component.html',
  styleUrl: './alerts.component.scss'
})
export class AlertsComponent implements OnInit {
  active: any[] = [];
  recent: any[] = [];
  busyAlertIds = new Set<number>();
  feedback = '';
  filterCode = '';
  filterSeverity = 'ALL';
  filterOrigin = 'ALL';
  filterPackType = 'ALL';
  filterOwner = '';
  recentState = 'ALL';
  recentAcknowledged = 'ALL';

  activeCols = ['alertCode', 'severity', 'title', 'origin', 'context', 'owner', 'createdAt', 'actions'];
  recentCols  = ['alertCode', 'severity', 'origin', 'context', 'owner', 'active', 'acknowledged', 'createdAt'];

  constructor(
    private readonly api: ApiService,
    readonly auth: AuthService,
    readonly packCatalog: PackCatalogService
  ) {}

  ngOnInit(): void {
    this.packCatalog.loadPacks();
    this.reloadAlerts();
  }

  get severityOptions(): string[] {
    return ['ALL', ...this.uniqueValues([...this.active, ...this.recent].map((alert) => alert?.severity))];
  }

  get originOptions(): string[] {
    return ['ALL', ...this.uniqueValues([...this.active, ...this.recent].map((alert) => alert?.source))];
  }

  get packTypeOptions(): string[] {
    return ['ALL', ...this.uniqueValues([...this.active, ...this.recent].map((alert) => alert?.packType))];
  }

  get filteredActive(): any[] {
    return this.active.filter((alert) => this.matchesSharedFilters(alert));
  }

  get filteredRecent(): any[] {
    return this.recent.filter((alert) => {
      if (!this.matchesSharedFilters(alert)) {
        return false;
      }

      if (this.recentState === 'ACTIVE' && !alert?.active) {
        return false;
      }

      if (this.recentState === 'RESOLVED' && alert?.active) {
        return false;
      }

      if (this.recentAcknowledged === 'ACK' && !alert?.acknowledged) {
        return false;
      }

      if (this.recentAcknowledged === 'UNACK' && alert?.acknowledged) {
        return false;
      }

      return true;
    });
  }
  resetFilters(): void {
    this.filterCode = '';
    this.filterSeverity = 'ALL';
    this.filterOrigin = 'ALL';
    this.filterPackType = 'ALL';
    this.filterOwner = '';
    this.recentState = 'ALL';
    this.recentAcknowledged = 'ALL';
  }

  acknowledge(alertId: number): void {
    this.setBusy(alertId, true);
    this.feedback = '';

    this.api.acknowledgeAlert(alertId).subscribe({
      next: () => {
        this.feedback = 'Alert acknowledged.';
        this.reloadAlerts();
        this.setBusy(alertId, false);
      },
      error: (e) => {
        console.error('acknowledgeAlert failed', e);
        this.feedback = e?.error?.message ?? 'Could not acknowledge the alert.';
        this.setBusy(alertId, false);
      }
    });
  }

  resolve(alertId: number): void {
    this.setBusy(alertId, true);
    this.feedback = '';

    this.api.resolveAlert(alertId).subscribe({
      next: () => {
        this.feedback = 'Alert resolved.';
        this.reloadAlerts();
        this.setBusy(alertId, false);
      },
      error: (e) => {
        console.error('resolveAlert failed', e);
        this.feedback = e?.error?.message ?? 'Could not resolve the alert.';
        this.setBusy(alertId, false);
      }
    });
  }

  isBusy(alertId: number): boolean {
    return this.busyAlertIds.has(alertId);
  }

  alertContextTitle(alert: any): string {
    const pack = this.findPackForAlert(alert);
    if (pack) {
      return pack.label?.trim() || pack.packageCode;
    }

    return 'Unassigned pack';
  }

  alertContextMeta(alert: any): string {
    const pack = this.findPackForAlert(alert);
    const packType = alert?.packType ?? '-';
    const bmsId = alert?.bmsId ?? alert?.bms_id ?? '-';

    if (pack) {
      return `${pack.packageCode} | ${packType} | BMS ${bmsId}`;
    }

    return `${packType} | BMS ${bmsId}`;
  }

  alertOwnerMeta(alert: any): string {
    const pack = this.findPackForAlert(alert);
    if (!pack) {
      return this.auth.isAdmin() ? 'Unknown owner' : 'My pack';
    }

    return this.auth.isAdmin()
      ? `${pack.ownerFullName} (${pack.ownerEmail})`
      : pack.ownerFullName;
  }

  alertOrigin(alert: any): string {
    return alert?.source ?? '-';
  }

  exportActiveCsv(): void {
    const rows = this.filteredActive.map((alert) => ({
      code: alert?.alertCode ?? '',
      severity: alert?.severity ?? '',
      title: alert?.title ?? '',
      origin: this.alertOrigin(alert),
      pack: this.alertContextTitle(alert),
      context: this.alertContextMeta(alert),
      belongsTo: this.alertOwnerMeta(alert),
      createdAt: alert?.createdAt ?? ''
    }));
    this.downloadCsv('active-alerts.csv', rows);
  }

  exportRecentCsv(): void {
    const rows = this.filteredRecent.map((alert) => ({
      code: alert?.alertCode ?? '',
      severity: alert?.severity ?? '',
      origin: this.alertOrigin(alert),
      pack: this.alertContextTitle(alert),
      context: this.alertContextMeta(alert),
      belongsTo: this.alertOwnerMeta(alert),
      active: String(Boolean(alert?.active)),
      acknowledged: String(Boolean(alert?.acknowledged)),
      createdAt: alert?.createdAt ?? ''
    }));
    this.downloadCsv('recent-alerts.csv', rows);
  }

  private reloadAlerts(): void {
    this.api.getActiveAlerts().subscribe({
      next: (x) => this.active = x,
      error: (e) => console.error('getActiveAlerts failed', e)
    });

    this.api.getRecentAlerts(50).subscribe({
      next: (x) => this.recent = x,
      error: (e) => console.error('getRecentAlerts failed', e)
    });
  }

  private setBusy(alertId: number, busy: boolean): void {
    if (busy) {
      this.busyAlertIds.add(alertId);
      return;
    }

    this.busyAlertIds.delete(alertId);
  }

  private findPackForAlert(alert: any) {
    const bmsId = String(alert?.bmsId ?? alert?.bms_id ?? '');
    const packType = String(alert?.packType ?? '').toUpperCase();

    if (!bmsId || !packType) {
      return null;
    }

    return this.packCatalog.packs().find((pack) => {
      const targetBms = packType === 'LFP' ? pack.lfpBmsId : pack.supercapBmsId;
      return targetBms === bmsId;
    }) ?? null;
  }

  private matchesSharedFilters(alert: any): boolean {
    const code = this.filterCode.trim().toLowerCase();
    const owner = this.filterOwner.trim().toLowerCase();

    if (code) {
      const haystack = [
        alert?.alertCode,
        alert?.title,
        this.alertContextTitle(alert),
        this.alertContextMeta(alert)
      ].join(' ').toLowerCase();

      if (!haystack.includes(code)) {
        return false;
      }
    }

    if (this.filterSeverity !== 'ALL' && alert?.severity !== this.filterSeverity) {
      return false;
    }

    if (this.filterOrigin !== 'ALL' && this.alertOrigin(alert) !== this.filterOrigin) {
      return false;
    }

    if (this.filterPackType !== 'ALL' && String(alert?.packType ?? '').toUpperCase() !== this.filterPackType) {
      return false;
    }

    if (owner && !this.alertOwnerMeta(alert).toLowerCase().includes(owner)) {
      return false;
    }

    return true;
  }

  private uniqueValues(values: any[]): string[] {
    return Array.from(new Set(values.filter((value) => typeof value === 'string' && value.trim()).map((value) => value.trim()))).sort();
  }

  private downloadCsv(filename: string, rows: Array<Record<string, string>>): void {
    if (!rows.length) {
      this.feedback = 'There is no data to export for the current filters.';
      return;
    }

    const headers = Object.keys(rows[0]);
    const csv = [
      headers.join(','),
      ...rows.map((row) => headers.map((header) => this.escapeCsv(row[header] ?? '')).join(','))
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    link.click();
    URL.revokeObjectURL(url);
  }

  private escapeCsv(value: string): string {
    const normalized = String(value ?? '');
    if (/[",\n]/.test(normalized)) {
      return `"${normalized.replace(/"/g, '""')}"`;
    }
    return normalized;
  }
}


