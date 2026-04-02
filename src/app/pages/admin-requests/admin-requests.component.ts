import { Component, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/api.service';

@Component({
  selector: 'app-admin-requests',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  templateUrl: './admin-requests.component.html',
  styleUrl: './admin-requests.component.scss'
})
export class AdminRequestsComponent implements OnInit {
  requests: any[] = [];
  loading = true;
  feedback = '';

  constructor(private readonly api: ApiService) {}

  ngOnInit(): void {
    this.reload();
  }

  reload(): void {
    this.loading = true;
    this.feedback = '';

    this.api.getPendingPackageRequests().subscribe({
      next: (requests) => {
        this.requests = (requests ?? []).map((request) => ({
          ...request,
          adminComment: '',
          lfpBmsId: '',
          supercapBmsId: '',
          saving: false
        }));
        this.loading = false;
      },
      error: () => {
        this.requests = [];
        this.loading = false;
        this.feedback = 'Could not load pending requests.';
      }
    });
  }

  approve(request: any): void {
    request.saving = true;
    this.api.approvePackageRequest(request.id, {
      adminComment: request.adminComment ?? '',
      lfpBmsId: request.lfpBmsId ?? '',
      supercapBmsId: request.supercapBmsId ?? ''
    }).subscribe({
      next: () => {
        request.saving = false;
        this.feedback = `Request #${request.id} approved.`;
        this.reload();
      },
      error: () => {
        request.saving = false;
        this.feedback = `Could not approve request #${request.id}.`;
      }
    });
  }

  reject(request: any): void {
    request.saving = true;
    this.api.rejectPackageRequest(request.id, {
      adminComment: request.adminComment ?? ''
    }).subscribe({
      next: () => {
        request.saving = false;
        this.feedback = `Request #${request.id} rejected.`;
        this.reload();
      },
      error: () => {
        request.saving = false;
        this.feedback = `Could not reject request #${request.id}.`;
      }
    });
  }
}
