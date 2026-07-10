<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateReportRequest extends FormRequest
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
        return [
            'reported_user_id' => [
                'required',
                'uuid',
                Rule::exists('users', 'id'),
                Rule::notIn([$this->user()->id]),
            ],
            'pod_id' => ['nullable', 'uuid', Rule::exists('pods', 'id')],
            'reason' => ['required', 'string'],
        ];
    }
}
