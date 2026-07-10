<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateReportRequest;
use App\Http\Requests\UpdateReportRequest;
use App\Models\Report;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class ReportController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/v1/reports
     */
    public function store(CreateReportRequest $request): JsonResponse
    {
        $report = Report::create([
            'reporter_id' => $request->user()->id,
            'reported_user_id' => $request->validated('reported_user_id'),
            'pod_id' => $request->validated('pod_id'),
            'reason' => $request->validated('reason'),
            'status' => 'open',
        ]);

        $report->load(['reporter:id,name', 'reportedUser:id,name', 'pod:id,goal_category,status']);

        return $this->success($this->formatReport($report), null, 201);
    }

    /**
     * GET /api/v1/reports
     */
    public function index(): JsonResponse
    {
        Gate::authorize('viewAny', Report::class);

        $reports = Report::query()
            ->with(['reporter:id,name', 'reportedUser:id,name', 'pod:id,goal_category,status'])
            ->where('status', 'open')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (Report $report) => $this->formatReport($report));

        return $this->success($reports);
    }

    /**
     * PATCH /api/v1/reports/{id}
     */
    public function update(UpdateReportRequest $request, Report $report): JsonResponse
    {
        Gate::authorize('update', $report);

        $report->update($request->validated());
        $report->load(['reporter:id,name', 'reportedUser:id,name', 'pod:id,goal_category,status']);

        return $this->success($this->formatReport($report));
    }

    /**
     * @return array<string, mixed>
     */
    private function formatReport(Report $report): array
    {
        return [
            'id' => $report->id,
            'reporter' => $report->reporter ? [
                'id' => $report->reporter->id,
                'name' => $report->reporter->name,
            ] : null,
            'reported_user' => $report->reportedUser ? [
                'id' => $report->reportedUser->id,
                'name' => $report->reportedUser->name,
            ] : null,
            'pod' => $report->pod,
            'reason' => $report->reason,
            'status' => $report->status,
            'created_at' => $report->created_at?->toIso8601String(),
        ];
    }
}
