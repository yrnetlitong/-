<template>
  <div class="image-uploader">
    <div
      v-for="(item, index) in photo"
      :key="item + '-' + index"
      class="image-uploader__item">
      <img v-lazy="item" :alt="`已上传图片 ${index + 1}`"/>
      <button
        v-if="!disabled"
        type="button"
        class="image-uploader__remove"
        :aria-label="`删除第 ${index + 1} 张图片`"
        @click="deleteImg(index)">
        <i class="el-icon-delete" aria-hidden="true"></i>
      </button>
    </div>

    <label
      v-if="photo.length < limit"
      v-loading="loading"
      :class="['image-uploader__add', { 'is-disabled': disabled }]">
      <i class="el-icon-plus" aria-hidden="true"></i>
      <span>上传图片</span>
      <input
        type="file"
        accept="image/gif,image/jpeg,image/png"
        :disabled="disabled || loading"
        @change="addImage"/>
    </label>
  </div>
</template>

<script>
const MAX_FILE_SIZE = 10 * 1024 * 1024
const IMAGE_TYPES = ['image/gif', 'image/jpeg', 'image/png']

export default {
  name: 'UploadImage',
  props: {
    limit: {
      type: Number,
      default: 1
    },
    disabled: Boolean,
    isCompress: Boolean,
    value: {
      type: [String, Array, File, Blob],
      default: ''
    }
  },
  data() {
    return {
      photo: [],
      loading: false
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(value) {
        if (typeof value === 'string') {
          this.photo = value ? [value] : []
        } else if (Array.isArray(value)) {
          this.photo = value.slice()
        } else if (value instanceof File || value instanceof Blob) {
          this.readPreview(value)
        } else {
          this.photo = []
        }
      }
    }
  },
  methods: {
    emitValue() {
      this.$emit('input', this.limit === 1 ? (this.photo[0] || '') : this.photo.slice())
    },
    deleteImg(index) {
      this.photo.splice(index, 1)
      this.emitValue()
      this.$emit('update:value', this.limit === 1 ? '' : this.photo.slice())
    },
    readPreview(file) {
      const reader = new FileReader()
      reader.onload = (event) => {
        this.photo = [event.target.result]
      }
      reader.onerror = () => this.$message.error('图片读取失败')
      reader.readAsDataURL(file)
    },
    compress(file) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onerror = () => reject(new Error('图片读取失败'))
        reader.onload = (event) => {
          const img = new Image()
          img.onerror = () => reject(new Error('图片解析失败'))
          img.onload = () => {
            const canvas = document.createElement('canvas')
            const width = Math.min(720, img.width)
            const ratio = width / img.width
            canvas.width = width
            canvas.height = Math.round(img.height * ratio)
            canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height)
            canvas.toBlob(
              blob => blob ? resolve(blob) : reject(new Error('图片压缩失败')),
              'image/jpeg',
              .9
            )
          }
          img.src = event.target.result
        }
        reader.readAsDataURL(file)
      })
    },
    async addImage(event) {
      const input = event.target
      const file = input.files && input.files[0]
      if (!file) {
        return
      }
      if (!IMAGE_TYPES.includes(file.type)) {
        input.value = ''
        this.$message.error('请上传 GIF、JPG、JPEG 或 PNG 格式图片')
        return
      }
      if (file.size > MAX_FILE_SIZE) {
        input.value = ''
        this.$message.error('上传图片不能超过 10MB')
        return
      }

      this.loading = true
      this.$emit('uploading', true)
      try {
        const uploadFile = this.isCompress ? await this.compress(file) : file
        const formData = new FormData()
        const uploadName = this.isCompress
          ? file.name.replace(/\.[^.]+$/, '') + '.jpg'
          : file.name
        formData.append('file', uploadFile, uploadName)
        const res = await this.$http.post('/upload/uploadImage', formData)
        if (res.data.code !== 0) {
          throw new Error(res.data.msg || '上传失败')
        }
        const data = res.data.data
        const url = Array.isArray(data) ? data[0] : data
        if (!url) {
          throw new Error('上传成功但未返回图片地址')
        }
        this.photo.push(url)
        this.emitValue()
      } catch (e) {
        this.$message.error(e.message || '上传失败')
      } finally {
        input.value = ''
        this.loading = false
        this.$emit('uploading', false)
      }
    }
  }
}
</script>

<style scoped>
.image-uploader {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.image-uploader__item,
.image-uploader__add {
  width: 100px;
  height: 100px;
  box-sizing: border-box;
  border: 1px solid #DCDFE6;
  border-radius: 6px;
  overflow: hidden;
}

.image-uploader__item {
  position: relative;
  background: #F5F7FA;
}

.image-uploader__item img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-uploader__remove {
  position: absolute;
  top: 6px;
  right: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  padding: 0;
  color: #FFF;
  border: 0;
  border-radius: 50%;
  background: rgba(0, 0, 0, .62);
  cursor: pointer;
  opacity: 0;
  transition: opacity .2s, background-color .2s;
}

.image-uploader__item:hover .image-uploader__remove,
.image-uploader__remove:focus-visible {
  opacity: 1;
}

.image-uploader__remove:hover {
  background: #F56C6C;
}

.image-uploader__add {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: #909399;
  background: #FAFAFA;
  cursor: pointer;
  transition: color .2s, border-color .2s, background-color .2s;
}

.image-uploader__add:hover,
.image-uploader__add:focus-within {
  color: #409EFF;
  border-color: #409EFF;
  background: #F5FAFF;
}

.image-uploader__add.is-disabled {
  color: #C0C4CC;
  border-color: #EBEEF5;
  background: #F5F7FA;
  cursor: not-allowed;
}

.image-uploader__add i {
  font-size: 24px;
}

.image-uploader__add span {
  font-size: 12px;
  line-height: 1;
}

.image-uploader__add input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
}

@media (hover: none) {
  .image-uploader__remove {
    opacity: 1;
  }
}
</style>
