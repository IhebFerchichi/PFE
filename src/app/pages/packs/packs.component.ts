import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { MatTabsModule } from '@angular/material/tabs';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatSelectModule } from '@angular/material/select';
import { MatFormFieldModule } from '@angular/material/form-field';
import { Subscription, interval } from 'rxjs';
import { ApiService } from '../../core/api.service';
import { LineChartComponent, LinePoint } from '../../shared/line-chart/line-chart.component';

@Component({
  selector: 'app-packs',
  standalone: true,
  imports: [
    CommonModule,
    MatTabsModule,
    MatCardModule,
    MatProgressSpinnerModule,
    DatePipe,
    LineChartComponent,
    MatButtonToggleModule,
    MatSelectModule,
    MatFormFieldModule
  ],
  templateUrl: './packs.component.html',
  styleUrl: './packs.component.scss'
})
export class PacksComponent implements OnInit, OnDestroy {
  loading = true;

  lfpLatest: any | null = null;
  scLatest: any | null = null;

  lfpCells: any[] = [];
  scCells: any[] = [];

  lfpV: LinePoint[] = [];
  lfpI: LinePoint[] = [];
  lfpT: LinePoint[] = [];

  scV: LinePoint[] = [];
  scI: LinePoint[] = [];
  scT: LinePoint[] = [];

  selectedLfpCell: number | null = null;
  selectedScCell: number | null = null;

  lfpCellSeries: LinePoint[] = [];
  scCellSeries: LinePoint[] = [];

  private readonly windowMinutes = 60;
  private watchSub?: Subscription;

  private lastLfpTs: string | null = null;
  private lastScTs: string | null = null;

  constructor(private api: ApiService) {}

  ngOnInit(): void {
    this.initialLoad();

    this.watchSub = interval(3000).subscribe(() => {
      this.checkForNewLfp();
      this.checkForNewSupercap();
    });
  }

  ngOnDestroy(): void {
    this.watchSub?.unsubscribe();
  }

  private initialLoad(): void {
    this.loading = true;

    this.api.getLfpLatest(1).subscribe({
      next: (x) => {
        this.lfpLatest = Array.isArray(x) ? (x[0] ?? null) : x;
        this.lastLfpTs = this.lfpLatest?.ts ?? null;
      },
      error: (e) => console.error('getLfpLatest failed', e)
    });

    this.api.getSupercapLatest(1).subscribe({
      next: (x) => {
        this.scLatest = Array.isArray(x) ? (x[0] ?? null) : x;
        this.lastScTs = this.scLatest?.ts ?? null;
      },
      error: (e) => console.error('getSupercapLatest failed', e)
    });

    this.loadLatestCells();
    this.reloadCharts();
  }

  private checkForNewLfp(): void {
    this.api.getLfpLatest(1).subscribe({
      next: (x) => {
        const latest = Array.isArray(x) ? (x[0] ?? null) : x;
        const newTs = latest?.ts ?? null;

        if (newTs && newTs !== this.lastLfpTs) {
          this.lastLfpTs = newTs;
          this.lfpLatest = latest;

          this.refreshLfpData();
        }
      },
      error: (e) => console.error('checkForNewLfp failed', e)
    });
  }

  private checkForNewSupercap(): void {
    this.api.getSupercapLatest(1).subscribe({
      next: (x) => {
        const latest = Array.isArray(x) ? (x[0] ?? null) : x;
        const newTs = latest?.ts ?? null;

        if (newTs && newTs !== this.lastScTs) {
          this.lastScTs = newTs;
          this.scLatest = latest;

          this.refreshSupercapData();
        }
      },
      error: (e) => console.error('checkForNewSupercap failed', e)
    });
  }

  private refreshLfpData(): void {
    this.loadLfpCells();
    this.loadLfpHistory();

    if (this.selectedLfpCell !== null) {
      this.selectLfpCell(this.selectedLfpCell);
    }
  }

  private refreshSupercapData(): void {
    this.loadSupercapCells();
    this.loadSupercapHistory();

    if (this.selectedScCell !== null) {
      this.selectScCell(this.selectedScCell);
    }
  }

  private loadLatestCells(): void {
    this.loadLfpCells();
    this.loadSupercapCells();
  }

  private loadLfpCells(): void {
    this.api.getLfpCellsLatest(16).subscribe({
      next: (x) => {
        this.lfpCells = Array.isArray(x) ? x : [];
      },
      error: (e) => {
        console.error('getLfpCellsLatest failed', e);
        this.lfpCells = [];
      }
    });
  }

  private loadSupercapCells(): void {
    this.api.getSupercapCellsLatest(16).subscribe({
      next: (x) => {
        this.scCells = Array.isArray(x) ? x : [];
      },
      error: (e) => {
        console.error('getSupercapCellsLatest failed', e);
        this.scCells = [];
      }
    });
  }

  private rangeIsoLastMinutes(mins: number): { from: string; to: string } {
    const to = new Date();
    const from = new Date(to.getTime() - mins * 60_000);
    return { from: from.toISOString(), to: to.toISOString() };
  }

  private pick(row: any, camel: string, snake: string): any {
    return row?.[camel] ?? row?.[snake];
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
        y: Number(this.pick(x, camelField, snakeField))
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

  reloadCharts(): void {
    this.loadLfpHistory();
    this.loadSupercapHistory();
  }

  private loadLfpHistory(): void {
    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getLfpHistory(from, to).subscribe({
      next: (rows) => {
        const r = Array.isArray(rows) ? rows : [];
        this.lfpV = this.toSeries(r, 'packVoltage', 'pack_voltage');
        this.lfpI = this.toSeries(r, 'packCurrent', 'pack_current');
        this.lfpT = this.toSeries(r, 'temperature', 'temperature');
        this.loading = false;
      },
      error: (e) => {
        console.error('getLfpHistory failed', e);
        this.lfpV = [];
        this.lfpI = [];
        this.lfpT = [];
        this.loading = false;
      }
    });
  }

  private loadSupercapHistory(): void {
    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getSupercapHistory(from, to).subscribe({
      next: (rows) => {
        const r = Array.isArray(rows) ? rows : [];
        this.scV = this.toSeries(r, 'packVoltage', 'pack_voltage');
        this.scI = this.toSeries(r, 'packCurrent', 'pack_current');
        this.scT = this.toSeries(r, 'temperature', 'temperature');
        this.loading = false;
      },
      error: (e) => {
        console.error('getSupercapHistory failed', e);
        this.scV = [];
        this.scI = [];
        this.scT = [];
        this.loading = false;
      }
    });
  }

  selectLfpCell(i: number): void {
    this.selectedLfpCell = i;
    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getLfpCellHistory(i, from, to).subscribe({
      next: (rows) => {
        const r = Array.isArray(rows) ? rows : [];
        this.lfpCellSeries = this.toCellSeries(r);
      },
      error: (e) => {
        console.error('getLfpCellHistory failed', e);
        this.lfpCellSeries = [];
      }
    });
  }

  selectScCell(i: number): void {
    this.selectedScCell = i;
    const { from, to } = this.rangeIsoLastMinutes(this.windowMinutes);

    this.api.getSupercapCellHistory(i, from, to).subscribe({
      next: (rows) => {
        const r = Array.isArray(rows) ? rows : [];
        this.scCellSeries = this.toCellSeries(r);
      },
      error: (e) => {
        console.error('getSupercapCellHistory failed', e);
        this.scCellSeries = [];
      }
    });
  }

  clearLfpCell(): void {
    this.selectedLfpCell = null;
    this.lfpCellSeries = [];
  }

  clearScCell(): void {
    this.selectedScCell = null;
    this.scCellSeries = [];
  }

  byIndex(a: any, b: any): number {
    return (a?.cellIndex ?? a?.cell_index ?? 0) - (b?.cellIndex ?? b?.cell_index ?? 0);
  }

  latestValue(row: any, camel: string, snake: string): any {
    return this.pick(row, camel, snake);
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
}