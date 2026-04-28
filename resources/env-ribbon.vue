<!-- @format -->

<template>
    <div class="ribbon" :style="cssVars">
        <slot> </slot>
    </div>
</template>

<script>
export default {
    props: {
        color: String,
        width: String,
    },
    computed: {
        cssVars() {
            return {
                '--ribbon-color': this.color,
                '--ribbon-width': this.width,
            }
        },
    },
}
</script>

<style>
@import './env-ribbon.css';
</style>
