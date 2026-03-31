import { Component, OnInit } from '@angular/core';
import { CommonModule,DatePipe  } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { ApiService } from '../../core/api.service';

@Component({
  selector: 'app-alerts',
  standalone: true,
  imports: [CommonModule, MatTableModule, DatePipe],
  templateUrl: './alerts.component.html',
  styleUrl: './alerts.component.scss'
})
export class AlertsComponent implements OnInit {
  active: any[] = [];
  recent: any[] = [];

  activeCols = ['alertCode', 'severity', 'packType', 'title', 'createdAt'];
  recentCols  = ['alertCode', 'severity', 'packType', 'active', 'createdAt'];

  constructor(private api: ApiService) {}

  ngOnInit(): void {
    this.api.getActiveAlerts().subscribe({
      next: (x) => this.active = x,
      error: (e) => console.error('getActiveAlerts failed', e)
    });

    this.api.getRecentAlerts(50).subscribe({
      next: (x) => this.recent = x,
      error: (e) => console.error('getRecentAlerts failed', e)
    });
  }
}