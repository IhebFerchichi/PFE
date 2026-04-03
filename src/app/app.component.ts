import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { NzLayoutModule } from 'ng-zorro-antd/layout';
import { NzMenuModule } from 'ng-zorro-antd/menu';
import { Router } from '@angular/router';
import { Subscription, interval } from 'rxjs';
import { AuthService } from './core/auth.service';
import { ApiService } from './core/api.service';
import { PackCatalogService } from './core/pack-catalog.service';

type AlertToast = {
  id: string;
  title: string;
  code: string;
  severity: string;
  source: string;
  packType: string;
  bmsId: string;
  packLabel: string;
  ownerLabel: string | null;
};

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterModule, MatToolbarModule, MatButtonModule, NzLayoutModule, NzMenuModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'batterypack-ui';
  alertToasts: AlertToast[] = [];
  private seenAlertIds = new Set<string>();
  private pollSub?: Subscription;
  private toastTimers = new Map<string, ReturnType<typeof setTimeout>>();
  private primed = false;

  constructor(
    readonly auth: AuthService,
    private readonly router: Router,
    private readonly api: ApiService,
    readonly packCatalog: PackCatalogService
  ) {
    this.auth.restoreSession();
  }

  ngOnInit(): void {
    this.packCatalog.loadPacks();
    this.startAlertPolling();
  }

  ngOnDestroy(): void {
    this.pollSub?.unsubscribe();
    this.toastTimers.forEach((timer) => clearTimeout(timer));
    this.toastTimers.clear();
  }

  get showShell(): boolean {
    return !['/login', '/signup', '/verify-email', '/forgot-password', '/reset-password']
      .some((path) => this.router.url.startsWith(path));
  }

  logout(): void {
    this.resetAlertNotifications();
    this.auth.logout();
  }

  dismissToast(id: string): void {
    this.alertToasts = this.alertToasts.filter((toast) => toast.id !== id);

    const timer = this.toastTimers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.toastTimers.delete(id);
    }
  }

  private startAlertPolling(): void {
    this.pollAlertState();
    this.pollSub = interval(5000).subscribe(() => this.pollAlertState());
  }

  private pollAlertState(): void {
    if (!this.auth.isAuthenticated()) {
      this.resetAlertNotifications();
      return;
    }

    this.api.getActiveAlerts().subscribe({
      next: (alerts) => this.processActiveAlerts(Array.isArray(alerts) ? alerts : []),
      error: (error) => console.error('alert polling failed', error)
    });
  }

  private processActiveAlerts(alerts: any[]): void {
    const currentIds = new Set(alerts.map((alert) => this.alertIdentity(alert)));

    if (!this.primed) {
      this.seenAlertIds = currentIds;
      this.primed = true;
      return;
    }

    const freshAlerts = alerts.filter((alert) => !this.seenAlertIds.has(this.alertIdentity(alert)));
    this.seenAlertIds = currentIds;

    for (const alert of freshAlerts) {
      this.pushToast(alert);
    }
  }

  private pushToast(alert: any): void {
    const id = this.alertIdentity(alert);
    const toast: AlertToast = {
      id,
      title: alert?.title ?? 'New alert detected',
      code: alert?.alertCode ?? 'ALERT',
      severity: alert?.severity ?? 'UNKNOWN',
      source: alert?.source ?? '-',
      packType: alert?.packType ?? 'PACK',
      bmsId: alert?.bmsId ?? alert?.bms_id ?? '-',
      packLabel: this.findPackLabel(alert),
      ownerLabel: this.findOwnerLabel(alert)
    };

    this.alertToasts = [toast, ...this.alertToasts.filter((existing) => existing.id !== id)].slice(0, 4);

    const existingTimer = this.toastTimers.get(id);
    if (existingTimer) {
      clearTimeout(existingTimer);
    }

    const timer = setTimeout(() => this.dismissToast(id), 35000);
    this.toastTimers.set(id, timer);
  }

  private alertIdentity(alert: any): string {
    return String(
      alert?.id ??
      `${alert?.alertCode ?? 'alert'}-${alert?.bmsId ?? alert?.bms_id ?? 'na'}-${alert?.createdAt ?? alert?.created_at ?? 'now'}`
    );
  }

  private resetAlertNotifications(): void {
    this.primed = false;
    this.seenAlertIds.clear();
    this.alertToasts = [];
    this.toastTimers.forEach((timer) => clearTimeout(timer));
    this.toastTimers.clear();
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

  private findPackLabel(alert: any): string {
    const pack = this.findPackForAlert(alert);
    return pack ? (pack.label?.trim() || pack.packageCode) : 'Unassigned pack';
  }

  private findOwnerLabel(alert: any): string | null {
    if (!this.auth.isAdmin()) {
      return null;
    }

    const pack = this.findPackForAlert(alert);
    return pack ? `${pack.ownerFullName} (${pack.ownerEmail})` : 'Unknown owner';
  }
}
