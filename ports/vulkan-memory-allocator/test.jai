#import "Basic";
Vma :: #import "vulkan-memory-allocator";

// Complete implementation compilation/setup gate; device and allocator parity pending.
main :: () {
    Vma.initialize_program();
    print("VulkanMemoryAllocator native module initialization passed\n");
}
