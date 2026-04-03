import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTabsModule } from '@angular/material/tabs';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { Subscription, interval } from 'rxjs';
import { ApiService, SavedChartMarker } from '../../core/api.service';
import { ChartMarker, LineChartComponent, LinePoint } from '../../shared/line-chart/line-chart.component';
import { PackCatalogService } from '../../core/pack-catalog.service';
import { AuthService } from '../../core/auth.service';

type ExpandedChart = {
  key: string;
  title: string;
  yLabel: string;
  points: LinePoint[];
  markers: ChartMarker[];
};

@Component({
  selector: 'app-packs',
  standalone: true,
  imports: [CommonModule, FormsModule, MatTabsModule, MatCardModule, MatProgressSpinnerModule, DatePipe, LineChartComponent],
  templateUrl: './packs.component.html',
  styleUrl: './packs.component.scss'
})
export class PacksComponent implements OnInit, OnDestroy {
  loading = true;
  expandedChart: ExpandedChart | null = null;
  expandedHistoryLoading = false;
  expandedSearchAt = '';
  expandedFrom = '';
  expandedTo = '';
  expandedHistoryHint = 'Showing the recent loaded window. Load the full history or fetch around an exact time.';
  private expandedManualPoints: LinePoint[] | null = null;
  lfpCellFrom = '';
  lfpCellTo = '';
  scCellFrom = '';
  scCellTo = '';
  lfpCellHistoryHint = 'Showing the recent one-hour window for this cell.';
  scCellHistoryHint = 'Showing the recent one-hour window for this cell.';
  lfpCellHistoryLoading = false;
  scCellHistoryLoading = false;

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
  lfpCellMarkers: ChartMarker[] = [];
  scCellMarkers: ChartMarker[] = [];

  private readonly compactPointCount = 10;
  private readonly windowMinutes = 60;
  private readonly sessionStartedAt = Date.now();
  private readonly chartMarkers = new Map<string, ChartMarker[]>();
  private loadedMarkerContext = '';
  private watchSub?: Subscription;
  private initialized = false;
  private lfpCellHistoryMode: 'recent' | 'manual' = 'recent';
  private scCellHistoryMode: 'recent' | 'manual' = 'recent';
  private lfpCellManualRange: { from: string; to: string } | null = null;
  private scCellManualRange: { from: string; to: string } | null = null;

  constructor(
    private readonly api: ApiService,
    readonly packCatalog: PackCatalogService,
    readonly auth: AuthService
  ) {}

  ngOnInit(): void {
    this.packCatalog.loadPacks();
    this.loadPackMarkers();
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
    this.loadPackMarkers();
    this.refreshDerivedState();
    this.reloadTelemetry(false);
  }

  openExpandedChart(key: string, title: string, yLabel: string, points: LinePoint[]): void {
    this.expandedChart = {
      key,
      title,
      yLabel,
      points: [...points],
      markers: this.getMarkers(key)
    };
    this.expandedManualPoints = null;
    this.expandedSearchAt = '';
    this.expandedFrom = '';
    this.expandedTo = '';
    this.expandedHistoryHint = 'Showing the recent loaded window. Load the full history or fetch around an exact time.';
  }

  closeExpandedChart(): void {
    this.expandedChart = null;
    this.expandedManualPoints = null;
  }

  addExpandedMarker(): void {
    if (!this.expandedChart) {
      return;
    }

    this.addMarker(this.expandedChart.key, this.expandedChart.points);
  }

  exportExpandedCsv(): void {
    if (!this.expandedChart) {
      return;
    }

    this.exportPointsCsv(
      `${this.slugify(this.expandedChart.title)}.csv`,
      this.expandedChart.title,
      this.expandedChart.points,
      this.expandedChart.yLabel
    );
  }

  loadExpandedFullHistory(): void {
    this.fetchExpandedHistoryWindow('2000-01-01T00:00:00.000Z', new Date().toISOString(), 'Showing full stored history for this chart.');
  }

  fetchExpandedAroundSearch(): void {
    if (!this.expandedSearchAt) {
      return;
    }

    const target = new Date(this.expandedSearchAt);
    if (Number.isNaN(target.getTime())) {
      return;
    }

    const from = new Date(target.getTime() - 30 * 60_000);
    const to = new Date(target.getTime() + 30 * 60_000);
    this.fetchExpandedHistoryWindow(
      from.toISOString(),
      to.toISOString(),
      `Showing data from ${from.toLocaleString()} to ${to.toLocaleString()}.`
    );
  }

  fetchExpandedDateRange(): void {
    if (!this.expandedFrom || !this.expandedTo) {
      return;
    }

    const from = new Date(this.expandedFrom);
    const to = new Date(this.expandedTo);

    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
      this.expandedHistoryHint = 'Please enter a valid start and end date/time.';
      return;
    }

    if (from.getTime() >= to.getTime()) {
      this.expandedHistoryHint = 'The end date/time must be after the start date/time.';
      return;
    }

    this.fetchExpandedHistoryWindow(
      from.toISOString(),
      to.toISOString(),
      `Showing data from ${from.toLocaleString()} to ${to.toLocaleString()}.`
    );
  }

  useRecentExpandedWindow(): void {
    this.expandedManualPoints = null;
    if (!this.expandedChart) {
      return;
    }

    this.expandedChart = {
      ...this.expandedChart,
      points: this.resolveExpandedPoints(this.expandedChart.key),
      markers: this.getMarkers(this.expandedChart.key)
    };
    this.expandedHistoryHint = 'Showing the recent loaded window. Load the full history or fetch around an exact time.';
  }

  addLfpCellMarker(): void {
    if (this.selectedLfpCell === null) {
      return;
    }

    this.addMarker(`lfp-cell-${this.selectedLfpCell}`, this.lfpCellPoints);
  }

  addScCellMarker(): void {
    if (this.selectedScCell === null) {
      return;
    }

    this.addMarker(`sc-cell-${this.selectedScCell}`, this.scCellPoints);
  }

  exportLfpCellCsv(): void {
    if (this.selectedLfpCell === null) {
      return;
    }

    this.exportPointsCsv(
      `lfp-cell-${this.selectedLfpCell}-history.csv`,
      `LFP Cell ${this.selectedLfpCell} Voltage History`,
      this.lfpCellPoints,
      'V'
    );
  }

  exportScCellCsv(): void {
    if (this.selectedScCell === null) {
      return;
    }

    this.exportPointsCsv(
      `supercap-cell-${this.selectedScCell}-history.csv`,
      `Supercap Cell ${this.selectedScCell} Voltage History`,
      this.scCellPoints,
      'V'
    );
  }

  selectLfpCell(i: number): void {
    const bmsId = this.selectedPack?.lfpBmsId ?? null;

    if (!bmsId) {
      this.clearLfpCell();
      return;
    }

    this.selectedLfpCell = i;
    this.useRecentLfpCellWindow();
  }

  selectScCell(i: number): void {
    const bmsId = this.selectedPack?.supercapBmsId ?? null;

    if (!bmsId) {
      this.clearScCell();
      return;
    }

    this.selectedScCell = i;
    this.useRecentScCellWindow();
  }

  useRecentLfpCellWindow(): void {
    if (this.selectedLfpCell === null) {
      return;
    }

    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);
    this.lfpCellHistoryMode = 'recent';
    this.lfpCellManualRange = null;
    this.lfpCellFrom = '';
    this.lfpCellTo = '';
    this.loadLfpCellHistory(
      this.selectedLfpCell,
      from,
      to,
      'Showing the recent one-hour window for this cell.'
    );
  }

  useRecentScCellWindow(): void {
    if (this.selectedScCell === null) {
      return;
    }

    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);
    this.scCellHistoryMode = 'recent';
    this.scCellManualRange = null;
    this.scCellFrom = '';
    this.scCellTo = '';
    this.loadScCellHistory(
      this.selectedScCell,
      from,
      to,
      'Showing the recent one-hour window for this cell.'
    );
  }

  fetchLfpCellDateRange(): void {
    if (this.selectedLfpCell === null) {
      return;
    }

    const range = this.parseDateRange(this.lfpCellFrom, this.lfpCellTo);
    if (!range) {
      this.lfpCellHistoryHint = 'Please enter a valid start and end date/time for the selected LFP cell.';
      return;
    }

    this.lfpCellHistoryMode = 'manual';
    this.lfpCellManualRange = range;
    this.loadLfpCellHistory(
      this.selectedLfpCell,
      range.from,
      range.to,
      `Showing data from ${new Date(range.from).toLocaleString()} to ${new Date(range.to).toLocaleString()}.`
    );
  }

  fetchScCellDateRange(): void {
    if (this.selectedScCell === null) {
      return;
    }

    const range = this.parseDateRange(this.scCellFrom, this.scCellTo);
    if (!range) {
      this.scCellHistoryHint = 'Please enter a valid start and end date/time for the selected supercap cell.';
      return;
    }

    this.scCellHistoryMode = 'manual';
    this.scCellManualRange = range;
    this.loadScCellHistory(
      this.selectedScCell,
      range.from,
      range.to,
      `Showing data from ${new Date(range.from).toLocaleString()} to ${new Date(range.to).toLocaleString()}.`
    );
  }

  clearLfpCell(): void {
    this.selectedLfpCell = null;
    this.lfpCellHistoryRows = [];
    this.lfpCellPoints = [];
    this.lfpCellMarkers = [];
    this.lfpCellFrom = '';
    this.lfpCellTo = '';
    this.lfpCellHistoryHint = 'Showing the recent one-hour window for this cell.';
    this.lfpCellHistoryLoading = false;
    this.lfpCellHistoryMode = 'recent';
    this.lfpCellManualRange = null;
  }

  clearScCell(): void {
    this.selectedScCell = null;
    this.scCellHistoryRows = [];
    this.scCellPoints = [];
    this.scCellMarkers = [];
    this.scCellFrom = '';
    this.scCellTo = '';
    this.scCellHistoryHint = 'Showing the recent one-hour window for this cell.';
    this.scCellHistoryLoading = false;
    this.scCellHistoryMode = 'recent';
    this.scCellManualRange = null;
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

    if (this.selectedLfpCell !== null && this.lfpCellHistoryMode === 'recent') {
      this.refreshSelectedLfpCell();
    }

    if (this.selectedScCell !== null && this.scCellHistoryMode === 'recent') {
      this.refreshSelectedScCell();
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

  private refreshSelectedLfpCell(): void {
    if (this.selectedLfpCell === null) {
      return;
    }

    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);
    this.loadLfpCellHistory(
      this.selectedLfpCell,
      from,
      to,
      'Showing the recent one-hour window for this cell.'
    );
  }

  private refreshSelectedScCell(): void {
    if (this.selectedScCell === null) {
      return;
    }

    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);
    this.loadScCellHistory(
      this.selectedScCell,
      from,
      to,
      'Showing the recent one-hour window for this cell.'
    );
  }

  private loadLfpCellHistory(cellIndex: number, fromIso: string, toIso: string, hint: string): void {
    const bmsId = this.selectedPack?.lfpBmsId ?? null;
    if (!bmsId) {
      this.clearLfpCell();
      return;
    }

    this.lfpCellHistoryLoading = true;
    this.api.getLfpCellHistory(cellIndex, fromIso, toIso, bmsId).subscribe({
      next: (rows) => {
        this.lfpCellHistoryRows = Array.isArray(rows) ? rows : [];
        this.lfpCellHistoryHint = this.lfpCellHistoryRows.length
          ? hint
          : 'No LFP cell telemetry was found in that requested time range.';
        this.refreshDerivedState();
        this.lfpCellHistoryLoading = false;
      },
      error: (e) => {
        console.error('getLfpCellHistory failed', e);
        this.lfpCellHistoryRows = [];
        this.lfpCellHistoryHint = 'Could not fetch that LFP cell history range right now.';
        this.refreshDerivedState();
        this.lfpCellHistoryLoading = false;
      }
    });
  }

  private loadScCellHistory(cellIndex: number, fromIso: string, toIso: string, hint: string): void {
    const bmsId = this.selectedPack?.supercapBmsId ?? null;
    if (!bmsId) {
      this.clearScCell();
      return;
    }

    this.scCellHistoryLoading = true;
    this.api.getSupercapCellHistory(cellIndex, fromIso, toIso, bmsId).subscribe({
      next: (rows) => {
        this.scCellHistoryRows = Array.isArray(rows) ? rows : [];
        this.scCellHistoryHint = this.scCellHistoryRows.length
          ? hint
          : 'No supercap cell telemetry was found in that requested time range.';
        this.refreshDerivedState();
        this.scCellHistoryLoading = false;
      },
      error: (e) => {
        console.error('getSupercapCellHistory failed', e);
        this.scCellHistoryRows = [];
        this.scCellHistoryHint = 'Could not fetch that supercap cell history range right now.';
        this.refreshDerivedState();
        this.scCellHistoryLoading = false;
      }
    });
  }

  private parseDateRange(fromValue: string, toValue: string): { from: string; to: string } | null {
    if (!fromValue || !toValue) {
      return null;
    }

    const from = new Date(fromValue);
    const to = new Date(toValue);

    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
      return null;
    }

    if (from.getTime() >= to.getTime()) {
      return null;
    }

    return {
      from: from.toISOString(),
      to: to.toISOString()
    };
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
        ts: new Date(x.ts).getTime(),
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
        ts: new Date(x.ts).getTime(),
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
    const markerContext = `${lfpBmsId ?? ''}|${supercapBmsId ?? ''}`;
    if (markerContext !== this.loadedMarkerContext) {
      this.loadedMarkerContext = markerContext;
      this.loadPackMarkers();
    }

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

    this.lfpVoltagePoints = this.compactSeries(this.liveSessionSeries(this.lfpVoltageFullPoints));
    this.lfpCurrentPoints = this.compactSeries(this.liveSessionSeries(this.lfpCurrentFullPoints));
    this.lfpTemperaturePoints = this.compactSeries(this.liveSessionSeries(this.lfpTemperatureFullPoints));
    this.supercapVoltagePoints = this.compactSeries(this.liveSessionSeries(this.supercapVoltageFullPoints));
    this.supercapCurrentPoints = this.compactSeries(this.liveSessionSeries(this.supercapCurrentFullPoints));
    this.supercapTemperaturePoints = this.compactSeries(this.liveSessionSeries(this.supercapTemperatureFullPoints));

    this.lfpCellPoints = this.toCellSeries(this.filterRowsByBms(this.lfpCellHistoryRows, lfpBmsId));
    this.scCellPoints = this.toCellSeries(this.filterRowsByBms(this.scCellHistoryRows, supercapBmsId));
    this.lfpCellMarkers = this.selectedLfpCell === null ? [] : this.getMarkers(`lfp-cell-${this.selectedLfpCell}`);
    this.scCellMarkers = this.selectedScCell === null ? [] : this.getMarkers(`sc-cell-${this.selectedScCell}`);
    this.syncExpandedChart();
  }

  private compactSeries(points: LinePoint[]): LinePoint[] {
    if (points.length <= this.compactPointCount) {
      return [...points];
    }

    return points.slice(-this.compactPointCount);
  }

  private liveSessionSeries(points: LinePoint[]): LinePoint[] {
    return points.filter((point) => point.ts >= this.sessionStartedAt);
  }

  private addMarker(key: string, points: LinePoint[]): void {
    if (!points.length) {
      return;
    }
    const markerContext = this.resolveMarkerContext(key);
    if (!markerContext) {
      return;
    }

    this.api.createChartMarker({
      packType: markerContext.packType,
      bmsId: markerContext.bmsId,
      chartKey: key,
      cellIndex: markerContext.cellIndex
    }).subscribe({
      next: (marker) => {
        this.applyMarkers([marker], markerContext.packType, markerContext.bmsId, false);
        this.syncExpandedChart();
      },
      error: (e) => {
        console.error('createChartMarker failed', e);
      }
    });
  }

  private fetchExpandedHistoryWindow(fromIso: string, toIso: string, hint: string): void {
    if (!this.expandedChart) {
      return;
    }

    const selectedPack = this.selectedPack;
    if (!selectedPack) {
      return;
    }

    this.expandedHistoryLoading = true;
    const key = this.expandedChart.key;

    let request$;
    if (key === 'lfp-voltage' || key === 'lfp-current' || key === 'lfp-temperature') {
      if (!selectedPack.lfpBmsId) {
        this.expandedHistoryLoading = false;
        return;
      }
      request$ = this.api.getLfpHistoryByBms(selectedPack.lfpBmsId, fromIso, toIso);
    } else if (key === 'supercap-voltage' || key === 'supercap-current' || key === 'supercap-temperature') {
      if (!selectedPack.supercapBmsId) {
        this.expandedHistoryLoading = false;
        return;
      }
      request$ = this.api.getSupercapHistoryByBms(selectedPack.supercapBmsId, fromIso, toIso);
    } else {
      this.expandedHistoryLoading = false;
      return;
    }

    request$.subscribe({
      next: (rows: any[]) => {
        const normalizedRows = Array.isArray(rows) ? rows : [];
        const points = key.endsWith('voltage')
          ? this.toSeries(normalizedRows, 'packVoltage', 'pack_voltage')
          : key.endsWith('current')
            ? this.toSeries(normalizedRows, 'packCurrent', 'pack_current')
            : this.toSeries(normalizedRows, 'temperature', 'temperature');

        this.expandedChart = {
          ...this.expandedChart!,
          points,
          markers: this.getMarkers(key)
        };
        this.expandedManualPoints = [...points];
        this.expandedHistoryHint = points.length
          ? hint
          : 'No telemetry was found in that requested time range.';
        this.expandedHistoryLoading = false;
      },
      error: (e) => {
        console.error('fetchExpandedHistoryWindow failed', e);
        this.expandedHistoryHint = 'Could not fetch that history range right now.';
        this.expandedHistoryLoading = false;
      }
    });
  }

  private getMarkers(key: string): ChartMarker[] {
    return [...(this.chartMarkers.get(key) ?? [])];
  }

  private loadPackMarkers(): void {
    const lfpBmsId = this.selectedPack?.lfpBmsId ?? null;
    const supercapBmsId = this.selectedPack?.supercapBmsId ?? null;

    this.chartMarkers.clear();
    this.lfpCellMarkers = [];
    this.scCellMarkers = [];
    this.syncExpandedChart();

    if (lfpBmsId) {
      this.api.getChartMarkers('LFP', lfpBmsId).subscribe({
        next: (markers) => {
          this.applyMarkers(markers, 'LFP', lfpBmsId, true);
        },
        error: (e) => console.error('getChartMarkers LFP failed', e)
      });
    }

    if (supercapBmsId) {
      this.api.getChartMarkers('SUPERCAP', supercapBmsId).subscribe({
        next: (markers) => {
          this.applyMarkers(markers, 'SUPERCAP', supercapBmsId, true);
        },
        error: (e) => console.error('getChartMarkers Supercap failed', e)
      });
    }
  }

  private applyMarkers(markers: SavedChartMarker[], packType: string, bmsId: string, replaceExisting: boolean): void {
    const relevant = (markers ?? []).filter((marker) => marker.packType === packType && marker.bmsId === bmsId);
    const byKey = new Map<string, ChartMarker[]>();

    for (const marker of relevant) {
      const chartMarker = this.toChartMarker(marker);
      const existing = byKey.get(marker.chartKey) ?? [];
      existing.push(chartMarker);
      byKey.set(marker.chartKey, existing);
    }

    for (const [key, rows] of byKey.entries()) {
      const merged = replaceExisting
        ? rows
        : [...this.getMarkers(key), ...rows].filter((marker, index, all) => all.findIndex((x) => x.id === marker.id) === index);
      this.chartMarkers.set(key, merged.sort((a, b) => a.at - b.at));
    }

    this.lfpCellMarkers = this.selectedLfpCell === null ? [] : this.getMarkers(`lfp-cell-${this.selectedLfpCell}`);
    this.scCellMarkers = this.selectedScCell === null ? [] : this.getMarkers(`sc-cell-${this.selectedScCell}`);
    this.syncExpandedChart();
  }

  private toChartMarker(marker: SavedChartMarker): ChartMarker {
    const markedAt = new Date(marker.markedAt);
    return {
      id: String(marker.id),
      at: markedAt.getTime(),
      label: markedAt.toLocaleString([], {
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
    };
  }

  private syncExpandedChart(): void {
    if (!this.expandedChart) {
      return;
    }

    this.expandedChart = {
      ...this.expandedChart,
      points: this.expandedManualPoints ? [...this.expandedManualPoints] : this.resolveExpandedPoints(this.expandedChart.key),
      markers: this.getMarkers(this.expandedChart.key)
    };
  }

  private resolveExpandedPoints(key: string): LinePoint[] {
    switch (key) {
      case 'lfp-voltage':
        return [...this.lfpVoltageFullPoints];
      case 'lfp-current':
        return [...this.lfpCurrentFullPoints];
      case 'lfp-temperature':
        return [...this.lfpTemperatureFullPoints];
      case 'supercap-voltage':
        return [...this.supercapVoltageFullPoints];
      case 'supercap-current':
        return [...this.supercapCurrentFullPoints];
      case 'supercap-temperature':
        return [...this.supercapTemperatureFullPoints];
      default:
        if (key.startsWith('lfp-cell-')) {
          return [...this.lfpCellPoints];
        }

        if (key.startsWith('sc-cell-')) {
          return [...this.scCellPoints];
        }

        return [...this.expandedChart?.points ?? []];
    }
  }

  private resolveMarkerContext(key: string): { packType: string; bmsId: string; cellIndex: number | null } | null {
    const selectedPack = this.selectedPack;
    if (!selectedPack) {
      return null;
    }

    if (key.startsWith('lfp-cell-')) {
      return {
        packType: 'LFP',
        bmsId: selectedPack.lfpBmsId ?? '',
        cellIndex: this.selectedLfpCell
      };
    }

    if (key.startsWith('sc-cell-')) {
      return {
        packType: 'SUPERCAP',
        bmsId: selectedPack.supercapBmsId ?? '',
        cellIndex: this.selectedScCell
      };
    }

    if (key.startsWith('lfp-')) {
      return {
        packType: 'LFP',
        bmsId: selectedPack.lfpBmsId ?? '',
        cellIndex: null
      };
    }

    if (key.startsWith('supercap-')) {
      return {
        packType: 'SUPERCAP',
        bmsId: selectedPack.supercapBmsId ?? '',
        cellIndex: null
      };
    }

    return null;
  }
  private exportPointsCsv(filename: string, title: string, points: LinePoint[], yLabel: string): void {
    if (!points.length) {
      return;
    }

    const rows = points.map((point) => ({
      chart: title,
      timestamp: new Date(point.ts).toISOString(),
      localTime: new Date(point.ts).toLocaleString(),
      value: String(point.y),
      unit: yLabel
    }));

    this.downloadCsv(filename, rows);
  }

  private downloadCsv(filename: string, rows: Array<Record<string, string>>): void {
    if (!rows.length) {
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
    if (/[\",\n]/.test(normalized)) {
      return `"${normalized.replace(/"/g, '""')}"`;
    }
    return normalized;
  }

  private slugify(value: string): string {
    return value
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '') || 'chart-history';
  }
}
