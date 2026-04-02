import { Component, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/api.service';

@Component({
  selector: 'app-requests',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  templateUrl: './requests.component.html',
  styleUrl: './requests.component.scss'
})
export class RequestsComponent implements OnInit {
  requests: any[] = [];
  requestedLabel = '';
  reason = '';
  loading = true;
  saving = false;
  feedback = '';

  constructor(private readonly api: ApiService) {}

  ngOnInit(): void {
    this.reload();
  }

  reload(): void {
    this.loading = true;
    this.api.getMyPackageRequests().subscribe({
      next: (requests) => {
        this.requests = requests ?? [];
        this.loading = false;
      },
      error: () => {
        this.requests = [];
        this.loading = false;
      }
    });
  }

  submit(): void {
    if (!this.requestedLabel.trim() || !this.reason.trim()) {
      this.feedback = 'Please provide a package label and request reason.';
      return;
    }

    this.saving = true;
    this.feedback = '';

    this.api.createPackageRequest({
      requestedLabel: this.requestedLabel.trim(),
      reason: this.reason.trim()
    }).subscribe({
      next: () => {
        this.requestedLabel = '';
        this.reason = '';
        this.feedback = 'Request submitted successfully.';
        this.saving = false;
        this.reload();
      },
      error: () => {
        this.feedback = 'Could not submit your request right now.';
        this.saving = false;
      }
    });
  }
}
