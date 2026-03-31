import { Component, OnInit } from '@angular/core';
import { CommonModule ,DatePipe} from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ApiService } from '../../core/api.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatChipsModule, MatProgressSpinnerModule,DatePipe],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  loading = true;

  lfpLatest: any | null = null;
  scLatest: any | null = null;

  activeAlerts: any[] = [];

  constructor(private api: ApiService) {}

  ngOnInit(): void {
    // load everything in parallel
    this.api.getLfpLatest(1).subscribe({
      next: (x) => this.lfpLatest = x?.[0] ?? null,
      error: (e) => console.error('getLfpLatest failed', e)
    });

    this.api.getSupercapLatest(1).subscribe({
      next: (x) => this.scLatest = x?.[0] ?? null,
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

  // simple "online" heuristic based on last timestamp (seconds)
  isOnline(ts?: string): boolean {
    if (!ts) return false;
    const last = new Date(ts).getTime();
    return (Date.now() - last) < 30_000; // 30 seconds
  }
}