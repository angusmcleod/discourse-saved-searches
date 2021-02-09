import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Ember.Controller.extend({
  saving: false,
  maxSavedSearches: 5,

  @discourseComputed("model.saved_searches")
  searchStrings() {
    console.log('searchstrings');
    let records = [];
    console.log(this.get("model.saved_searches"|| []));
    (this.get("model.saved_searches") || []).forEach((s) => {
      records.push({ query: s });
    });
    while (records.length < this.get("maxSavedSearches")) {
      records.push({ query: "" });
    }
    return records;
  },
    @discourseComputed("model.saved_tag_searches")
    tagSearchStrings() {
      console.log('tag searchstrings');
      console.log(this);
      let tag_records = [];
      console.log('get saved-tag-searches');
      var s = this.get("model.saved_tag_searches");
      console.log(s);
      console.log(typeof s);
      if (s){
      for (const [key, val] of Object.entries(s)) {
        console.log('val');
        console.log(val);
        let cat_tag = val.split(',');
        console.log(cat_tag);
        console.log(cat_tag[0]);
        let tag = (cat_tag[1]== "null") ? null : cat_tag[1];
        let category = (cat_tag[0]== "null") ? null : cat_tag[0];
        if (cat_tag[0] && cat_tag[1]) {
          tag_records.push( {category: category, tag: [tag] });
        }
      };
    };
      while (tag_records.length < this.get("maxSavedSearches")) {
        tag_records.push({ category: null, tag: null });
      }
      console.log('tag_records');
      console.log(tag_records);
      return tag_records;
    },

  actions: {
    save() {
      console.log('save!');
      console.log(this);
      console.log(this.get("tagSearchStrings"));
      this.setProperties({ saved: false, isSaving: true });

      const searches = this.get("searchStrings")
        .map((s) => {
          return s.query ? s.query : null;
        })
        .compact();

      this.set("model.saved_searches", searches);

      const tagSearches = this.get("tagSearchStrings")
        .map((s) => {
          console.log("tagSearches");
          let category = s.category ? s.category : null;
          let tag = s.tag ? s.tag[0] : null;
          console.log('tag');
            console.log(tag);
          console.log(s.tag);
          return (`${category},${tag}`);
        })
        .compact();

      this.set("model.saved_tag_searches", tagSearches);
      
      console.log('gonna put');
      console.log([searches, tagSearches]);

      return ajax("/saved_searches", {
        type: "PUT",
        dataType: "json",
        data: {
          searches: searches,
          tag_searches: tagSearches,
        },
      }).then((result, error) => {
        this.setProperties({ saved: true, isSaving: false });
        if (error) {
          popupAjaxError(error);
        }
      });
    },
  },
});
