<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateCheckInRequest;
use App\Models\CheckIn;
use App\Models\Pod;
use App\Services\StreakService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class CheckInController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly StreakService $streakService) {}

    /**
     * GET /api/v1/pods/{pod}/check-ins
     */
    public function index(Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $checkIns = $pod->checkIns()
            ->with('user:id,name,avatar_url')
            ->orderByDesc('check_in_date')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (CheckIn $checkIn) => $this->formatCheckIn($checkIn));

        return $this->success($checkIns);
    }

    /**
     * POST /api/v1/pods/{pod}/check-ins
     *
     * Creates a check-in for today's UTC calendar date. All members share the same
     * check-in day boundary in UTC regardless of their profile timezone, so streak
     * eligibility is evaluated consistently across timezones.
     */
    public function store(CreateCheckInRequest $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $today = $this->streakService->todayUtc()->toDateString();

        $alreadyCheckedIn = CheckIn::query()
            ->where('pod_id', $pod->id)
            ->where('user_id', $request->user()->id)
            ->whereDate('check_in_date', $today)
            ->exists();

        if ($alreadyCheckedIn) {
            return $this->error(
                'You have already checked in for today.',
                'check_in_already_exists',
                null,
                409
            );
        }

        $checkIn = $pod->checkIns()->create([
            'user_id' => $request->user()->id,
            'check_in_date' => $today,
            'note' => $request->validated('note'),
        ]);

        $checkIn->load('user:id,name,avatar_url');

        $this->streakService->recalculateAfterCheckIn($pod);

        return $this->success($this->formatCheckIn($checkIn), null, 201);
    }

    /**
     * GET /api/v1/pods/{pod}/streak
     */
    public function streak(Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        return $this->success($this->streakService->streakSummary($pod));
    }

    /**
     * @return array<string, mixed>
     */
    private function formatCheckIn(CheckIn $checkIn): array
    {
        $checkIn->loadMissing('user:id,name,avatar_url');

        return [
            'id' => $checkIn->id,
            'pod_id' => $checkIn->pod_id,
            'user' => [
                'id' => $checkIn->user->id,
                'name' => $checkIn->user->name,
                'avatar_url' => $checkIn->user->avatar_url,
            ],
            'check_in_date' => $checkIn->check_in_date?->toDateString(),
            'note' => $checkIn->note,
            'created_at' => $checkIn->created_at?->toIso8601String(),
        ];
    }
}
