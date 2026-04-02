import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { MatTabsModule } from '@angular/material/tabs';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { Subscription, interval } from 'rxjs';
import { ApiService } from '../../core/api.service';
import { LineChartComponent, LinePoint } from '../../shared/line-chart/line-chart.component';
import { PackCatalogService } from '../../core/pack-catalog.service';
import { AuthService } from '../../core/auth.service';

type ExpandedChart = {
  title: string;
  yLabel: string;
  points: LinePoint[];
};

@Component({
  selector: 'app-packs',
  standalone: true,
  imports: [CommonModule, MatTabsModule, MatCardModule, MatProgressSpinnerModule, DatePipe, LineChartComponent],
  templateUrl: './packs.component.html',
  styleUrl: './packs.component.scss'
})
export class PacksComponent implements OnInit, OnDestroy {
  loading = true;
  expandedChart: ExpandedChart | null = null;

  allLfpLatest: any[] = [];
  allScLatest: any[] = [];
  allLfpCells: any[] = [];
  allScCells: any[] = [];
  allLfpHistory: any[] = [];
  allScHistory: any[] = [];

  selectedLfpCell: number | null = null;
  selectedScCell: number | null = null;
  lfpCellHistoryRows: any[] = [];
  scCellHistoryRows: any[] = [];

  latestLfpRow: any | null = null;
  latestSupercapRow: any | null = null;
  lfpCellRows: any[] = [];
  scCellRows: any[] = [];

  lfpVoltagePoints: LinePoint[] = [];
  lfpCurrentPoints: LinePoint[] = [];
  lfpTemperaturePoints: LinePoint[] = [];
  supercapVoltagePoints: LinePoint[] = [];
  supercapCurrentPoints: LinePoint[] = [];
  supercapTemperaturePoints: LinePoint[] = [];
  lfpVoltageFullPoints: LinePoint[] = [];
  lfpCurrentFullPoints: LinePoint[] = [];
  lfpTemperatureFullPoints: LinePoint[] = [];
  supercapVoltageFullPoints: LinePoint[] = [];
  supercapCurrentFullPoints: LinePoint[] = [];
  supercapTemperatureFullPoints: LinePoint[] = [];
  lfpCellPoints: LinePoint[] = [];
  scCellPoints: LinePoint[] = [];

  private readonly compactPointCount = 10;
  private readonly windowMinutes = 60;
  private watchSub?: Subscription;
  private initialized = false;

  constructor(
    private readonly api: ApiService,
    readonly packCatalog: PackCatalogService,
    readonly auth: AuthService
  ) {}

  ngOnInit(): void {
    this.packCatalog.loadPacks();
    this.reloadTelemetry(true);
    this.watchSub = interval(3000).subscribe(() => this.reloadTelemetry(false));
  }

  ngOnDestroy(): void {
    this.watchSub?.unsubscribe();
  }

  get selectedPack() {
    return this.packCatalog.selectedPack();
  }

  choosePack(packageCode: string): void {
    this.packCatalog.setSelectedPack(packageCode);
    this.clearLfpCell();
    this.clearScCell();
    this.expandedChart = null;
    this.refreshDerivedState();
    this.reloadTelemetry(false);
  }

  openExpandedChart(title: string, yLabel: string, points: LinePoint[]): void {
    if (!points.length) {
      return;
    }

    this.expandedChart = {
      title,
      yLabel,
      points: [...points]
    };
  }

  closeExpandedChart(): void {
    this.expandedChart = null;
  }

  selectLfpCell(i: number): void {
    const bmsId = this.selectedPack?.lfpBmsId ?? null;

    if (!bmsId) {
      this.clearLfpCell();
      return;
    }

    this.selectedLfpCell = i;
    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getLfpCellHistory(i, from, to, bmsId).subscribe({
      next: (rows) => {
        this.lfpCellHistoryRows = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getLfpCellHistory failed', e);
        this.lfpCellHistoryRows = [];
        this.refreshDerivedState();
      }
    });
  }

  selectScCell(i: number): void {
    const bmsId = this.selectedPack?.supercapBmsId ?? null;

    if (!bmsId) {
      this.clearScCell();
      return;
    }

    this.selectedScCell = i;
    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getSupercapCellHistory(i, from, to, bmsId).subscribe({
      next: (rows) => {
        this.scCellHistoryRows = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getSupercapCellHistory failed', e);
        this.scCellHistoryRows = [];
        this.refreshDerivedState();
      }
    });
  }

  clearLfpCell(): void {
    this.selectedLfpCell = null;
    this.lfpCellHistoryRows = [];
    this.lfpCellPoints = [];
  }

  clearScCell(): void {
    this.selectedScCell = null;
    this.scCellHistoryRows = [];
    this.scCellPoints = [];
  }

  byIndex(a: any, b: any): number {
    return (a?.cellIndex ?? a?.cell_index ?? 0) - (b?.cellIndex ?? b?.cell_index ?? 0);
  }

  latestValue(row: any, camel: string, snake: string): any {
    return row?.[camel] ?? row?.[snake];
  }

  cellIndexOf(c: any): number {
    return c?.cellIndex ?? c?.cell_index ?? 0;
  }

  cellVoltageOf(c: any): any {
    return c?.cellVoltage ?? c?.cell_voltage ?? '-';
  }

  cellBalancingOf(c: any): boolean {
    return Boolean(c?.balancingOn ?? c?.balancing_on);
  }

  packDisplayName(pack: { label: string | null; packageCode: string }): string {
    return pack.label?.trim() || pack.packageCode;
  }

  packSubtitle(pack: { packageCode: string }): string {
    return `Code ${pack.packageCode}`;
  }

  private reloadTelemetry(showLoader = false): void {
    if (showLoader && !this.initialized) {
      this.loading = true;
    }

    this.loadLfpLatest();
    this.loadSupercapLatest();
    this.loadLfpCells();
    this.loadSupercapCells();
    this.loadLfpHistory();
    this.loadSupercapHistory();

    if (this.selectedLfpCell !== null) {
      this.selectLfpCell(this.selectedLfpCell);
    }

    if (this.selectedScCell !== null) {
      this.selectScCell(this.selectedScCell);
    }

    this.initialized = true;
  }

  private loadLfpLatest(): void {
    this.api.getLfpLatest(200).subscribe({
      next: (rows) => {
        this.allLfpLatest = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
        this.loading = false;
      },
      error: (e) => {
        console.error('getLfpLatest failed', e);
        this.allLfpLatest = [];
        this.refreshDerivedState();
        this.loading = false;
      }
    });
  }

  private loadSupercapLatest(): void {
    this.api.getSupercapLatest(200).subscribe({
      next: (rows) => {
        this.allScLatest = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getSupercapLatest failed', e);
        this.allScLatest = [];
        this.refreshDerivedState();
      }
    });
  }

  private loadLfpCells(): void {
    this.api.getLfpCellsLatest(500).subscribe({
      next: (rows) => {
        this.allLfpCells = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getLfpCellsLatest failed', e);
        this.allLfpCells = [];
        this.refreshDerivedState();
      }
    });
  }

  private loadSupercapCells(): void {
    this.api.getSupercapCellsLatest(500).subscribe({
      next: (rows) => {
        this.allScCells = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getSupercapCellsLatest failed', e);
        this.allScCells = [];
        this.refreshDerivedState();
      }
    });
  }

  private loadLfpHistory(): void {
    const bmsId = this.selectedPack?.lfpBmsId ?? null;

    if (!bmsId) {
      this.allLfpHistory = [];
      this.refreshDerivedState();
      return;
    }

    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getLfpHistoryByBms(bmsId, from, to).subscribe({
      next: (rows) => {
        this.allLfpHistory = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getLfpHistory failed', e);
        this.allLfpHistory = [];
        this.refreshDerivedState();
      }
    });
  }

  private loadSupercapHistory(): void {
    const bmsId = this.selectedPack?.supercapBmsId ?? null;

    if (!bmsId) {
      this.allScHistory = [];
      this.refreshDerivedState();
      return;
    }

    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getSupercapHistoryByBms(bmsId, from, to).subscribe({
      next: (rows) => {
        this.allScHistory = Array.isArray(rows) ? rows : [];
        this.refreshDerivedState();
      },
      error: (e) => {
        console.error('getSupercapHistory failed', e);
        this.allScHistory = [];
        this.refreshDerivedState();
      }
    });
  }

  private rangeIsoLastMinutes(mins: number): { from: string; to: string } {
    const to = new Date();
    const from = new Date(to.getTime() - mins * 60_000);
    return { from: from.toISOString(), to: to.toISOString() };
  }

  private toSeries(rows: any[], camelField: string, snakeField: string): LinePoint[] {
    return (rows ?? [])
      .filter((x) => x?.ts)
      .map((x) => ({
        t: new Date(x.ts).toLocaleTimeString([], {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        }),
        y: Number(x?.[camelField] ?? x?.[snakeField])
      }))
      .filter((p) => !Number.isNaN(p.y));
  }

  private toCellSeries(rows: any[]): LinePoint[] {
    return (rows ?? [])
      .filter((x) => x?.ts)
      .map((x) => ({
        t: new Date(x.ts).toLocaleTimeString([], {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        }),
        y: Number(x?.cellVoltage ?? x?.cell_voltage)
      }))
      .filter((p) => !Number.isNaN(p.y));
  }

  private findLatestForBms(rows: any[], bmsId: string | null): any | null {
    if (!bmsId) {
      return null;
    }

    return rows.find((row) => this.rowBmsId(row) === bmsId) ?? null;
  }

  private latestCellsForBms(rows: any[], bmsId: string | null): any[] {
    if (!bmsId) {
      return [];
    }

    const seen = new Set<number>();
    const filtered: any[] = [];

    for (const row of rows) {
      if (this.rowBmsId(row) !== bmsId) {
        continue;
      }

      const index = this.cellIndexOf(row);
      if (seen.has(index)) {
        continue;
      }

      seen.add(index);
      filtered.push(row);
    }

    return filtered.sort((a, b) => this.byIndex(a, b));
  }

  private filterRowsByBms(rows: any[], bmsId: string | null): any[] {
    if (!bmsId) {
      return [];
    }

    return rows.filter((row) => this.rowBmsId(row) === bmsId);
  }

  private rowBmsId(row: any): string | null {
    return row?.bmsId ?? row?.bms_id ?? row?.pack?.bmsId ?? row?.pack?.bms_id ?? null;
  }

  private refreshDerivedState(): void {
    const lfpBmsId = this.selectedPack?.lfpBmsId ?? null;
    const supercapBmsId = this.selectedPack?.supercapBmsId ?? null;

    this.latestLfpRow = this.findLatestForBms(this.allLfpLatest, lfpBmsId);
    this.latestSupercapRow = this.findLatestForBms(this.allScLatest, supercapBmsId);
    this.lfpCellRows = this.latestCellsForBms(this.allLfpCells, lfpBmsId);
    this.scCellRows = this.latestCellsForBms(this.allScCells, supercapBmsId);

    const lfpHistoryRows = this.filterRowsByBms(this.allLfpHistory, lfpBmsId);
    const supercapHistoryRows = this.filterRowsByBms(this.allScHistory, supercapBmsId);

    this.lfpVoltageFullPoints = this.toSeries(lfpHistoryRows, 'packVoltage', 'pack_voltage');
    this.lfpCurrentFullPoints = this.toSeries(lfpHistoryRows, 'packCurrent', 'pack_current');
    this.lfpTemperatureFullPoints = this.toSeries(lfpHistoryRows, 'temperature', 'temperature');
    this.supercapVoltageFullPoints = this.toSeries(supercapHistoryRows, 'packVoltage', 'pack_voltage');
    this.supercapCurrentFullPoints = this.toSeries(supercapHistoryRows, 'packCurrent', 'pack_current');
    this.supercapTemperatureFullPoints = this.toSeries(supercapHistoryRows, 'temperature', 'temperature');

    this.lfpVoltagePoints = this.compactSeries(this.lfpVoltageFullPoints);
    this.lfpCurrentPoints = this.compactSeries(this.lfpCurrentFullPoints);
    this.lfpTemperaturePoints = this.compactSeries(this.lfpTemperatureFullPoints);
    this.supercapVoltagePoints = this.compactSeries(this.supercapVoltageFullPoints);
    this.supercapCurrentPoints = this.compactSeries(this.supercapCurrentFullPoints);
    this.supercapTemperaturePoints = this.compactSeries(this.supercapTemperatureFullPoints);

    this.lfpCellPoints = this.toCellSeries(this.filterRowsByBms(this.lfpCellHistoryRows, lfpBmsId));
    this.scCellPoints = this.toCellSeries(this.filterRowsByBms(this.scCellHistoryRows, supercapBmsId));
  }

  private compactSeries(points: LinePoint[]): LinePoint[] {
    if (points.length <= this.compactPointCount) {
      return [...points];
    }

    return points.slice(-this.compactPointCount);
  }
}
