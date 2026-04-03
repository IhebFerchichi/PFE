import {
  AfterViewInit,
  Component,
  ElementRef,
  Input,
  OnChanges,
  OnDestroy,
  SimpleChanges,
  ViewChild
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { Chart, ChartConfiguration, registerables } from 'chart.js';

Chart.register(...registerables);

export type LinePoint = { t: string; y: number; ts: number };
export type ChartMarker = { id: string; at: number; label: string };

const markerLinesPlugin = {
  id: 'markerLines',
  afterDatasetsDraw(chart: Chart, _args: unknown, pluginOptions: any) {
    const markers = (pluginOptions?.markers ?? []) as ChartMarker[];
    const points = (pluginOptions?.points ?? []) as LinePoint[];
    const datasetPoints = chart.getDatasetMeta(0)?.data ?? [];

    if (!markers.length || !points.length || !datasetPoints.length || !chart.chartArea) {
      return;
    }

    const { ctx, chartArea } = chart;
    ctx.save();

    for (const marker of markers) {
      let closestIndex = 0;
      let smallestDelta = Number.POSITIVE_INFINITY;

      for (let i = 0; i < points.length; i++) {
        const delta = Math.abs(points[i].ts - marker.at);
        if (delta < smallestDelta) {
          smallestDelta = delta;
          closestIndex = i;
        }
      }

      const element: any = datasetPoints[closestIndex];
      const x = element?.x;
      if (typeof x !== 'number') {
        continue;
      }

      ctx.strokeStyle = '#e02424';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(x, chartArea.top);
      ctx.lineTo(x, chartArea.bottom);
      ctx.stroke();

      ctx.font = '12px sans-serif';
      const labelWidth = ctx.measureText(marker.label).width + 12;
      const labelX = Math.min(Math.max(x - labelWidth / 2, chartArea.left + 4), chartArea.right - labelWidth - 4);

      ctx.fillStyle = '#e02424';
      ctx.fillRect(labelX, chartArea.top + 8, labelWidth, 22);
      ctx.fillStyle = '#ffffff';
      ctx.fillText(marker.label, labelX + 6, chartArea.top + 23);
    }

    ctx.restore();
  }
};

Chart.register(markerLinesPlugin);

@Component({
  selector: 'app-line-chart',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './line-chart.component.html',
  styleUrl: './line-chart.component.scss'
})
export class LineChartComponent implements AfterViewInit, OnChanges, OnDestroy {
  @Input() title = '';
  @Input() points: LinePoint[] = [];
  @Input() yLabel = '';
  @Input() height = 260;
  @Input() scrollable = false;
  @Input() pointWidth = 56;
  @Input() markers: ChartMarker[] = [];

  @ViewChild('canvas', { static: false }) canvas!: ElementRef<HTMLCanvasElement>;
  private chart?: Chart;
  private viewReady = false;
  private renderTimer?: ReturnType<typeof setTimeout>;

  ngAfterViewInit(): void {
    this.viewReady = true;
    this.scheduleRender();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['points'] || changes['title'] || changes['yLabel'] || changes['markers']) {
      this.scheduleRender();
    }
  }

  ngOnDestroy(): void {
    if (this.renderTimer) {
      clearTimeout(this.renderTimer);
    }
    this.chart?.destroy();
  }

  private scheduleRender(): void {
    if (this.renderTimer) {
      clearTimeout(this.renderTimer);
    }

    this.renderTimer = setTimeout(() => this.render(), 0);
  }

  private render(): void {
    if (!this.viewReady || !this.canvas?.nativeElement) {
      return;
    }

    const labels = (this.points ?? []).map((p) => p.t);
    const data = (this.points ?? []).map((p) => p.y);

    if (!this.chart) {
      this.chart = new Chart(this.canvas.nativeElement, {
        type: 'line',
        data: {
          labels,
          datasets: [
            {
              label: this.yLabel || this.title || 'Value',
              data,
              borderColor: '#2f4b93',
              backgroundColor: 'rgba(47, 75, 147, 0.14)',
              pointBackgroundColor: '#d9363e',
              pointBorderColor: '#ffffff',
              pointHoverBackgroundColor: '#d9363e',
              pointHoverBorderColor: '#ffffff',
              borderWidth: 3,
              pointRadius: data.length ? 2 : 0,
              pointHoverRadius: 5,
              tension: 0.32,
              fill: false
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: false,
          layout: {
            padding: {
              left: 6,
              right: 10,
              top: 6,
              bottom: 6
            }
          },
          interaction: {
            mode: 'index',
            intersect: false
          },
          plugins: {
            title: {
              display: false
            },
            legend: {
              display: true,
              position: 'top',
              align: 'start',
              labels: {
                usePointStyle: true,
                pointStyle: 'circle',
                boxWidth: 8,
                color: '#1f2a44',
                font: {
                  size: 12,
                  weight: 600
                }
              }
            },
            tooltip: {
              backgroundColor: '#233974',
              titleColor: '#ffffff',
              bodyColor: '#ffffff',
              borderColor: 'rgba(255,255,255,0.15)',
              borderWidth: 1,
              padding: 10,
              displayColors: true
            },
            markerLines: {
              markers: this.markers,
              points: this.points
            } as any
          },
          scales: {
            x: {
              border: {
                display: true
              },
              grid: {
                display: true,
                drawTicks: true,
                color: 'rgba(47, 75, 147, 0.08)'
              },
              ticks: {
                display: true,
                color: '#6b7893',
                maxRotation: 0,
                autoSkip: true,
                maxTicksLimit: 6,
                padding: 8
              }
            },
            y: {
              grace: '5%',
              border: {
                display: true
              },
              grid: {
                display: true,
                drawTicks: true,
                color: 'rgba(47, 75, 147, 0.08)'
              },
              ticks: {
                display: true,
                color: '#6b7893',
                padding: 8
              }
            }
          }
        }
      } as ChartConfiguration<'line'>);
      return;
    }

    const dataset = this.chart.data.datasets[0] as any;

    this.chart.data.labels = labels;
    dataset.label = this.yLabel || this.title || 'Value';
    dataset.data = data;
    dataset.pointRadius = data.length ? 2 : 0;
    (this.chart.options.plugins as any).markerLines = {
      markers: this.markers,
      points: this.points
    };
    this.chart.resize();
    this.chart.update('none');
  }

  get chartWidth(): number | null {
    if (!this.scrollable) {
      return null;
    }

    return Math.max((this.points?.length ?? 0) * this.pointWidth, 640);
  }
}
