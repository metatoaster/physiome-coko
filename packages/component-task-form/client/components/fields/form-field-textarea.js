import React from 'react';
import styled from 'styled-components';

import { FormFieldInlineTaskHolder } from './form-field-inline-task';
import { ConfirmationDialogContext } from './form-field-button';

import useFormValueBinding from './../../hooks/useFormValueBinding';
import useFormValidation, {formFieldClassNameWithValidations} from './../../hooks/useFormValidation';
import withFormField from './withFormField'

import { BlockLabel } from 'ds-theme/components/label';
import TextArea, { SmallTextArea } from 'ds-theme/components/text-area';
import ValidationIssueListing from 'ds-theme/components/validation-issue-listing';


const FormStyledTextArea = styled(TextArea)`
  ${FormFieldInlineTaskHolder} &,
  &.in-dialog {
      font-size: 14px;
      padding: 10px;
      min-height: 92px;
  }
`;

const FormStyledSmallTextArea = styled(SmallTextArea)`
  ${FormFieldInlineTaskHolder} &,
  &.in-dialog {
      font-size: 14px;
      padding: 10px;
      min-height: 92px;
  }
`;


function FormFieldTextArea({data, binding, description, formDefinition, formValidator, context, options = {}}) {

    const [value, _, handleInputChange] = useFormValueBinding(data, binding, "", (v) => v || "");
    const [validationIssues, clearValidationIssues] = useFormValidation(description, formDefinition, formValidator);
    const isInsideConfirmationDialog = context && context[0] === ConfirmationDialogContext;
    const { autoSizeHeight = false, small = false } = options;
    const TextAreaType = small ? FormStyledSmallTextArea : FormStyledTextArea;

    const handleInputChangeWithWarningsClear = (e) => {
        clearValidationIssues();
        handleInputChange(e);
    };

    const textInput = (
        <TextAreaType className={formFieldClassNameWithValidations(isInsideConfirmationDialog ? 'in-dialog' : '', validationIssues)}
            value={value || ""} onChange={handleInputChangeWithWarningsClear} autoSizeHeight={autoSizeHeight} rows={options.rows || 2}
            issue={validationIssues && validationIssues.length}  />
    );

    return (
        <React.Fragment>
            {options.label ? <BlockLabel>{options.label}</BlockLabel> : null}
            {textInput}
            { validationIssues ? <ValidationIssueListing issues={validationIssues} /> : null }
        </React.Fragment>
    );
}

export default withFormField(FormFieldTextArea);