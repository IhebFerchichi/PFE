import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export type VisiblePack = {
  id: number;
  packageCode: string;
  label: string | null;
  status: string;
  ownerUserId: number;
  ownerFullName: string;
  ownerEmail: string;
  lfpBmsId: string | null;
  supercapBmsId: string | null;
  createdAt: string;
};

@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = 'http://localhost:8080';

  constructor(private http: HttpClient) {}

  login(email: string, password: string) {
    return this.http.post<any>(`${this.baseUrl}/auth/login`, { email, password });
  }

  register(fullName: string, email: string, password: string) {
    return this.http.post<any>(`${this.baseUrl}/auth/register`, { fullName, email, password });
  }

  getMe() {
    return this.http.get<any>(`${this.baseUrl}/auth/me`);
  }

  getVisiblePacks(): Observable<VisiblePack[]> {
    return this.http.get<VisiblePack[]>(`${this.baseUrl}/packs/catalog`);
  }

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
    return this.getHistory('/packs/lfp/history', fromIso, toIso);
  }

  getLfpHistoryByBms(bmsId: string | null, fromIso: string, toIso: string) {
    return this.getHistory('/packs/lfp/history', fromIso, toIso, bmsId);
  }

  getSupercapHistory(fromIso: string, toIso: string) {
    return this.getHistory('/packs/supercap/history', fromIso, toIso);
  }

  getSupercapHistoryByBms(bmsId: string | null, fromIso: string, toIso: string) {
    return this.getHistory('/packs/supercap/history', fromIso, toIso, bmsId);
  }

  getLfpCellHistory(cellIndex: number, fromIso: string, toIso: string, bmsId?: string | null) {
    return this.getHistory(`/packs/lfp/cells/${cellIndex}/history`, fromIso, toIso, bmsId);
  }

  getSupercapCellHistory(cellIndex: number, fromIso: string, toIso: string, bmsId?: string | null) {
    return this.getHistory(`/packs/supercap/cells/${cellIndex}/history`, fromIso, toIso, bmsId);
  }

  createPackageRequest(payload: { requestedLabel: string; reason: string }) {
    return this.http.post<any>(`${this.baseUrl}/user/package-requests`, payload);
  }

  getMyPackageRequests() {
    return this.http.get<any[]>(`${this.baseUrl}/user/package-requests`);
  }

  getPendingPackageRequests() {
    return this.http.get<any[]>(`${this.baseUrl}/admin/package-requests/pending`);
  }

  approvePackageRequest(requestId: number, payload: { adminComment: string; lfpBmsId: string; supercapBmsId: string }) {
    return this.http.post<any>(`${this.baseUrl}/admin/package-requests/${requestId}/approve`, payload);
  }

  rejectPackageRequest(requestId: number, payload: { adminComment: string }) {
    return this.http.post<any>(`${this.baseUrl}/admin/package-requests/${requestId}/reject`, payload);
  }

  private getHistory(path: string, fromIso: string, toIso: string, bmsId?: string | null) {
    const params = [
      `from=${encodeURIComponent(fromIso)}`,
      `to=${encodeURIComponent(toIso)}`
    ];

    if (bmsId) {
      params.push(`bmsId=${encodeURIComponent(bmsId)}`);
    }

    return this.http.get<any[]>(`${this.baseUrl}${path}?${params.join('&')}`);
  }
}
