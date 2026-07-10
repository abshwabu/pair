<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateMatchingRequest extends FormRequest
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
            'goal_id' => [
                'required',
                'uuid',
                Rule::exists('goals', 'id')->where('user_id', $this->user()->id),
            ],
            'timezone_tolerance_hours' => ['required', 'integer', 'min:0', 'max:12'],
            'target_goal_id' => [
                'sometimes',
                'uuid',
                Rule::exists('goals', 'id')->where(function ($query) {
                    $query->where('user_id', '!=', $this->user()->id);
                }),
            ],
        ];
    }
}
