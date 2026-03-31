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

export type LinePoint = { t: string; y: number };

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

  @ViewChild('canvas', { static: false }) canvas!: ElementRef<HTMLCanvasElement>;
  private chart?: Chart;
  private viewReady = false;

  ngAfterViewInit(): void {
    this.viewReady = true;
    this.render();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['points'] || changes['title'] || changes['yLabel']) {
      setTimeout(() => this.render());
    }
  }

  ngOnDestroy(): void {
    this.chart?.destroy();
  }

  private render(): void {
    if (!this.viewReady || !this.canvas?.nativeElement) {
      return;
    }

    this.chart?.destroy();

    const labels = (this.points ?? []).map((p) => p.t);
    const data = (this.points ?? []).map((p) => p.y);

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
          }
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
              min: 0,
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
  }
}