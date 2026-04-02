import { Component, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ApiService } from '../../core/api.service';
import { PackCatalogService } from '../../core/pack-catalog.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatChipsModule, MatProgressSpinnerModule, DatePipe],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  loading = true;
  allLfpLatest: any[] = [];
  allScLatest: any[] = [];
  activeAlerts: any[] = [];

  constructor(
    private readonly api: ApiService,
    readonly packCatalog: PackCatalogService
  ) {}

  ngOnInit(): void {
    this.packCatalog.loadPacks();

    this.api.getLfpLatest(200).subscribe({
      next: (x) => this.allLfpLatest = Array.isArray(x) ? x : [],
      error: (e) => console.error('getLfpLatest failed', e)
    });

    this.api.getSupercapLatest(200).subscribe({
      next: (x) => this.allScLatest = Array.isArray(x) ? x : [],
      error: (e) => console.error('getSupercapLatest failed', e)
    });

    this.api.getActiveAlerts().subscribe({
      next: (x) => {
        this.activeAlerts = x ?? [];
        this.loading = false;
      },
      error: (e) => {
        console.error('getActiveAlerts failed', e);
        this.loading = false;
      }
    });
  }

  get selectedPack() {
    return this.packCatalog.selectedPack();
  }

  choosePack(packageCode: string): void {
    this.packCatalog.setSelectedPack(packageCode);
  }

  latestLfp(): any | null {
    return this.findLatestForBms(this.allLfpLatest, this.selectedPack?.lfpBmsId ?? null);
  }

  latestSupercap(): any | null {
    return this.findLatestForBms(this.allScLatest, this.selectedPack?.supercapBmsId ?? null);
  }

  selectedPackAlertCount(): number {
    const bmsIds = [this.selectedPack?.lfpBmsId, this.selectedPack?.supercapBmsId].filter(Boolean);
    if (!bmsIds.length) {
      return 0;
    }

    return this.activeAlerts.filter((alert) => bmsIds.includes(alert?.bmsId ?? alert?.bms_id)).length;
  }

  packDisplayName(pack: { label: string | null; packageCode: string }): string {
    return pack.label?.trim() || pack.packageCode;
  }

  isOnline(ts?: string): boolean {
    if (!ts) return false;
    const last = new Date(ts).getTime();
    return Date.now() - last < 30_000;
  }

  private findLatestForBms(rows: any[], bmsId: string | null): any | null {
    if (!bmsId) {
      return null;
    }

    return rows.find((row) => (row?.bmsId ?? row?.bms_id) === bmsId) ?? null;
  }
}
