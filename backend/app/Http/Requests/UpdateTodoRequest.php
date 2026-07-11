<?php

namespace App\Http\Requests;

use App\Models\Pod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateTodoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        /** @var Pod $pod */
        $pod = $this->route('pod');

        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'notes' => ['sometimes', 'nullable', 'string'],
            'due_date' => ['sometimes', 'nullable', 'date'],
            'assigned_to' => [
                'sometimes',
                'nullable',
                'uuid',
                Rule::exists('pod_members', 'user_id')
                    ->where(fn ($query) => $query->where('pod_id', $pod->id)->whereNull('left_at')),
            ],
            'my_completed' => ['sometimes', 'boolean'],
        ];
    }
}
