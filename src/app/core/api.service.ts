import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = 'http://localhost:8080';

  constructor(private http: HttpClient) {}

  getActiveAlerts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/alerts/active`);
  }

  getRecentAlerts(limit = 50): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/alerts/recent?limit=${limit}`);
  }

  getLfpLatest(limit = 50): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/packs/lfp/latest?limit=${limit}`);
  }

  getSupercapLatest(limit = 50): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/packs/supercap/latest?limit=${limit}`);
  }

  getLfpCellsLatest(limit = 160): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/packs/lfp/cells/latest?limit=${limit}`);
  }

  getSupercapCellsLatest(limit = 160): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/packs/supercap/cells/latest?limit=${limit}`);
  }

  getLfpHistory(fromIso: string, toIso: string) {
    return this.http.get<any[]>(
      `${this.baseUrl}/packs/lfp/history?from=${encodeURIComponent(fromIso)}&to=${encodeURIComponent(toIso)}`
    );
  }

  getSupercapHistory(fromIso: string, toIso: string) {
    return this.http.get<any[]>(
      `${this.baseUrl}/packs/supercap/history?from=${encodeURIComponent(fromIso)}&to=${encodeURIComponent(toIso)}`
    );
  }

  getLfpCellHistory(cellIndex: number, fromIso: string, toIso: string) {
    return this.http.get<any[]>(
      `${this.baseUrl}/packs/lfp/cells/${cellIndex}/history?from=${encodeURIComponent(fromIso)}&to=${encodeURIComponent(toIso)}`
    );
  }

  getSupercapCellHistory(cellIndex: number, fromIso: string, toIso: string) {
    return this.http.get<any[]>(
      `${this.baseUrl}/packs/supercap/cells/${cellIndex}/history?from=${encodeURIComponent(fromIso)}&to=${encodeURIComponent(toIso)}`
    );
  }
}