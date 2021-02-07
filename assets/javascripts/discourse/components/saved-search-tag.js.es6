import Component from "@ember/component";
import { action } from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  @discourseComputed("tagSearch")
  selectedTags: {
    get(value) {
        console.log('selectedTags');
        console.log(value);
        console.log(tagSearch);
      return value.split("|").filter(Boolean);
    },
  },
  selectedCategory: {
    get(value) {
        console.log('selectedCategory');
        console.log(value);
        console.log(selectedCategory);
      return value;
    },
  },

  @action
  changeSelectedTags(tags) {
      console.log('changeSelectedTags!!');
      console.log(this);
      console.log(tags);
      console.log('change tags cat');
      console.log(this.get("selectedCategory"));
    this.set("tagSearch.tags", tags.join("|"));
  },
  @action
  changeSelectedCategory(selectedCategory) {
      console.log('changeSelectedCategory!!');
      console.log(this);
      console.log(selectedCategory);
    this.set("tagSearch.category", selectedCategory);
    console.log(this);
  },
});
