package kernel

Slab_Allocator :: struct {
	object_size:      int,
	next_free_object: ^Slab_Free_Object,
}

Slab_Free_Object :: struct {
	next: ^Slab_Free_Object,
}

slab_create :: proc "contextless" (
	backing_memory: []byte,
	object_size: int,
) -> (
	allocator: Slab_Allocator,
) {
	if object_size < size_of(Slab_Free_Object) {
		return
	}

	object_count := len(backing_memory) / object_size
	next_free_object := &allocator.next_free_object

	for i in 0 ..< object_count {
		object := (^Slab_Free_Object)(&backing_memory[i * object_size])
		next_free_object^ = object
		next_free_object = &object.next
	}

	next_free_object^ = nil
	return
}

@(require_results)
slab_alloc :: proc "contextless" (allocator: ^Slab_Allocator) -> (ptr: rawptr, err: Error) {
	if allocator.next_free_object == nil {
		return nil, .Out_Of_Memory
	}

	free_object := allocator.next_free_object
	allocator.next_free_object = free_object.next
	return rawptr(free_object), .Ok
}

slab_free :: proc "contextless" (allocator: ^Slab_Allocator, ptr: rawptr) {
	slab_object_ptr := (^Slab_Free_Object)(ptr)
	slab_object_ptr.next = allocator.next_free_object
	allocator.next_free_object = slab_object_ptr
}
