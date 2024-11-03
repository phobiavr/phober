<template>
    <div style="margin-right: -0.5rem">
        <!-- Confirm Action Modal -->
        <component
            :is="selectedAction?.component"
            v-if="actionModalVisible"
            :show="actionModalVisible"
            class="text-left"
            :working="working"
            :selected-resources="selectedResources"
            :resource-name="resourceName"
            :action="selectedAction"
            :errors="errors"
            @confirm="runAction"
            @close="closeConfirmationModal"
        />

        <component
            :is="actionResponseData?.modal"
            v-if="responseModalVisible"
            :show="responseModalVisible"
            :data="actionResponseData"
            @confirm="handleResponseModalConfirm"
            @close="handleResponseModalClose"
        />

        <div class="ml-auto flex items-center pl-4">
            <div v-if="actions.length > 0" class="flex">
                <div
                    v-if="shouldShowButtons"
                    :dusk="`${triggerDuskAttribute}-button-group`"
                    class="flex gap-4 py-0"
                    :class="{ 'mr-4': shouldShowDropdown }"
                >
                    <template v-for="action in actions">
                        <button
                            v-if="action.showAsButton"
                            :key="action.uriKey"
                            :dusk="`${triggerDuskAttribute}-${action.uriKey}`"
                            :title="action.name"
                            :destructive="action.destructive"
                            class="bg-primary-500 hover:bg-primary-400 ring-primary-200 relative inline-flex h-9 cursor-pointer items-center justify-center rounded px-3 text-sm font-bold text-white shadow focus:outline-none focus:ring dark:text-gray-900 dark:ring-gray-600"
                            @click="() => handleActionClick(action.uriKey)"
                        >
                            {{ action.name }}
                        </button>
                    </template>
                </div>

                <Dropdown v-if="shouldShowDropdown">
                    <template #default>
                        <div>
                            <slot name="sr-only">
                                <span class="sr-only">{{ __('Standalone Actions') }}</span>
                            </slot>
                            <Button variant="action" icon="ellipsis-horizontal" />
                        </div>
                    </template>

                    <template #menu>
                        <DropdownMenu width="auto" class="px-1">
                            <ScrollWrap :height="250" class="divide-y divide-solid divide-gray-100 dark:divide-gray-800">
                                <slot />

                                <div v-if="actions.length > 0" class="py-1">
                                    <template v-for="action in actions">
                                        <DropdownMenuItem
                                            v-if="!action.showAsButton"
                                            :key="action.uriKey"
                                            :data-action-id="action.uriKey"
                                            as="button"
                                            class="border-none"
                                            :title="action.name"
                                            :destructive="action.destructive"
                                            @click="() => handleActionClick(action.uriKey)"
                                        >
                                            {{ action.name }}
                                        </DropdownMenuItem>
                                    </template>
                                </div>
                            </ScrollWrap>
                        </DropdownMenu>
                    </template>
                </Dropdown>
            </div>
        </div>
    </div>
</template>

<script setup>
import { useActions } from '@/composables/useActions';
import { computed } from 'vue';
import { useStore } from 'vuex';
import { Button } from 'laravel-nova-ui';

const store = useStore();

const emitter = defineEmits(['actionExecuted']);

const props = defineProps({
    resourceName: {},
    viaResource: {},
    viaResourceId: {},
    viaRelationship: {},
    relationshipType: {},
    actions: { type: Array, default: [] },
    selectedResources: { type: [Array, String], default: () => [] },
    endpoint: { type: String, default: null },
    triggerDuskAttribute: { type: String, default: null },
});

const {
    errors,
    actionModalVisible,
    responseModalVisible,
    openConfirmationModal,
    closeConfirmationModal,
    closeResponseModal,
    handleActionClick,
    selectedAction,
    working,
    executeAction,
    actionResponseData,
} = useActions(props, emitter, store);

const runAction = () => executeAction(() => emitter('actionExecuted'));

const handleResponseModalConfirm = () => {
    closeResponseModal();
    emitter('actionExecuted');
};

const handleResponseModalClose = () => {
    closeResponseModal();
    emitter('actionExecuted');
};

const shouldShowButtons = computed(() => {
    const showInDropdownList = props.actions.filter((action) => action.showAsButton === true);

    return showInDropdownList.length > 0;
});

const shouldShowDropdown = computed(() => {

    const showInDropdownList = props.actions.filter((action) => !(action.showAsButton === true));

    return showInDropdownList.length > 0;
});
</script>
